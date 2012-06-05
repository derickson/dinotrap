var app = app || {};
app.socket = null;
app.myname = null;
app.myid = null;
app.mypoints = 0

app.outsideGameZoneWarning = false;

app.map = {
	
	toRad: function(number) {
		return number * Math.PI / 180.0
	},
	
	calcDistance: function (lat1, lon1, lat2, lon2) {
		var R = 3956.6; // miles
		var dLat = app.map.toRad(lat2-lat1);
		var dLon = app.map.toRad(lon2-lon1);
		var lat1 = app.map.toRad(lat1);
		var lat2 = app.map.toRad(lat2);

		var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
		        Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
		var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
		var d = R * c;
		return d;
	},
	
	dirtyList: {},
	rexDict : {},
	
	init : function (position) {
		$('div#map_canvas').gmap({
			'center': position, 
			'zoom': 14 ,
			'streetViewControl': false,
			'mapTypeControl': false,
			'disableDefaultUI': false,
			'disableDoubleClickZoom': true,
			'draggable': false
		});

		$( 'div#game' ).live( 'pageshow',function(event, ui){
		  $('div#map_canvas').gmap("refresh");
		});
	},
	
	clearEverything : function () {
		$('#map_canvas').gmap('clear', 'markers');
		$('#map_canvas').gmap('clear', 'overlays');
	},
	
	
	placeTrex : function (m) {
		
		app.map.removeFromDirtyList(m.id);
		
		var r = app.map.rexDict[m.id];
		
		if(typeof r == 'undefined') {
			app.map.rexDict[m.id] = [];
			r = app.map.rexDict[m.id];
		}
		
		r.push(m);
		
		if(r.length > 8) {
			r.splice(0,1);
		}
		
		var t = 0.8;
		var w = 4; 		
		for(var i= r.length -2	; i >= Math.max(0, r.length -8) ; i--) {
			s = r[i];
			e = r[i+1];
			t -= 0.05;
			w = w / 1.2;
			app.map.drawLine(s.lat, s.lon, e.lat, e.lon, t, w);
		}
	
		$('#map_canvas').gmap('addMarker', 
			{ 
				'position': new google.maps.LatLng(m.lat, m.lon), 
				'icon': '/images/trex.png', 
				'bounds': false,
				 'zIndex': 3 
			} );
		
		
		
	},

	drawLine : function (a,b,c,d,t,w) {
		$('#map_canvas').gmap('addShape', 'Polyline', 
			{'strokeColor': "#EF0000", 
			 'strokeOpacity': t, 
			 'strokeWeight': w, 
			 'clickable': false,
			 'geodesic': true,
			 'path': [new google.maps.LatLng(a,b), new google.maps.LatLng(c,d)],
			 'zIndex': 2
			});
	},
	
	drawTrap: function( trap ) {
		var split = trap.location.split(",");
		var color = trap.survivorGuid === app.myid || trap.survivorId === app.myid ? "#0000EE" : "#EE00EE";
		
		
		$('#map_canvas').gmap('addShape', 'Circle', 
			{'strokeColor': color, 
			 'strokeOpacity': 0.8, 
			 'strokeWeight': 2,
			 'fillColor': color,
			 'fillOpacity': 0.2,
			 'clickable': false,
			 'center': new google.maps.LatLng(split[0], split[1]),
			 'radius': trap.distance * 1609.344, // meters in a mile
			 'zIndex': 1
			});
	},
	
	clearDirtyList: function() {
		for(var key in app.map.dirtyList) {
			delete app.map.dirtyList[key];
		}
	},
	
	removeFromDirtyList: function(key) {
		app.map.dirtyList[key] && delete app.map.dirtyList[key];
	},
	
	markDinosForDelete: function() {
		app.map.clearDirtyList();
		
		for(var key in app.map.rexDict) {
			app.map.dirtyList[key] = {dirty:true};
		}
	},
	
	deleteMarkedDinos: function() {
		for(var key in app.map.dirtyList) {
			app.map.rexDict[key] && delete app.map.rexDict[key];
		}
		app.map.clearDirtyList();
	}
};


app.pushModel = function() {
	$("span#nameSpan").text(app.myname);
	$("span#pointsSpan").text(app.mypoints);
};

// utility function: get geolocation from browser and pass it to a callback
app.myLocation = function(cb){
	if (navigator.geolocation) {
			navigator.geolocation.getCurrentPosition(
				function(position) {
					var lat = position.coords.latitude;
					var lon = position.coords.longitude;
					//alert(positioncoords.accuracy);
					
					//console.log(lat + ", " + lon);
					
					if(lon < -77.59 || 
						lon > -76.65 ||
						lat > 39.21 || 
						lat < 38.60 ) {
					
						// outside of game zone
						lat = 38.9094;
						lon = -77.0426; 
						if(! app.outsideGameZoneWarning){
							alert ("You are outside Washington D.C., so I am placing you at Dupont Circle.");
							app.outsideGameZoneWarning = true;
						}
						
						//console.log(lat + ", " + lon);
						cb(lat,lon);
							
					} else {
						// inside game zone
						cb(lat,lon);
					}
				},
				function(msg) {
					console.log('Error on myLocation: '+ msg);
				},
				{
					enableHighAccuracy: true,
					maximumAge: 10000,
					timeout: 5000
				}
			);		
	} else {
		console.log('GeoLocation not supported');
	}
};

// Step 2: login form calls this when submitted
app.login = function() {
	var name = $("input#name").val().toLowerCase();
	var reg	 = /^[\w\s\d]+$/
	if( reg.test(name) ) {
		app.initSocket(name);
	} else {
		alert("Please enter a valid name.")
	}
	
};

// Step 3: set up socket connection and handlers
app.initSocket = function(name) {
	app.socket = io.connect('/');

	app.socket.on('connect', function() {
		app.socket.emit('login', {"name": name});
	});
	
	app.socket.on("login-accepted", function(data) {
		app.myname = data.name;
		app.myid = data.id;
		app.mypoints = data.points;
		
		app.myLocation( app.initMobileMap );
		
	});
	
	app.socket.on('connect_failed', function () {
		alert("Connecting to socket.io totally failed");
		app.socket = null;
	})
	
	app.socket.on("dinos", function(data) {
		//console.log(data);
		

		app.map.clearEverything();
		
		$.each( data.dinos, function(i, m) {
			app.map.placeTrex(m);
		});
		
	});
	
	app.socket.on("trap-spring", function(data) {
		//console.log(data);
		if(app.myid === data.survivorId) {
			app.mypoints = data.points;
			app.pushModel();
			alert("A dino walked into your trap.  You now have "+ app.mypoints + " points!");
			app.nearMe();
		}
		
	});
	
	app.socket.on("trapPlaced", function(data) {
		app.map.drawTrap(data);
	});
	
	app.socket.on("newDinosAvailable", function() {
		//console.log("newDinosAvailable");
		app.nearMe();
	});
	
	app.socket.on("thingsNearYou", function(data) {
		//console.log('things near me');
		//console.log(data);
		
		app.map.markDinosForDelete();
		
		app.map.clearEverything();
		
		$.each( data.dinos, function(i, m) {
			app.map.placeTrex(m);
		});
		
		$.each( data.traps, function(i, t) {
			app.map.drawTrap(t);
		});
		
		app.map.deleteMarkedDinos();
		
	})
	
	
};

app.nearMe = function() {
	// get things near this client
	app.myLocation( function (lat, lon) {
		app.socket.emit("nearMe", {
			"name": app.myname,
			"id": app.myid,
			"lon": lon,
			"lat": lat
		});
	});
};

app.placeTrap = function() {
	
	if(app.socket !== null) {
		app.myLocation( function (lat, lon) {
			//app.map.recenter( ''+lat+', '+lon );
			app.socket.emit("placeTrap", {
				"name": app.myname,
				"id": app.myid,
				"lon": lon,
				"lat": lat
			})
		});
		
	} else {
		console.log("socket was null, not placing trap");
	}
	
};

	


app.initMobileMap = function(lat,lon) {
	var position = ''+lat+', '+lon;

	app.pushModel();

	app.map.init(position);

	
	$.mobile.changePage($("#game"));
	
	app.nearMe();
	
	
};


app.logout = function() {
	app.socket.disconnect();
	
	app.myname = null;
	app.myid = null;
	
	app.socket = null;
		
	document.location.href='/';

};



$(document).ready(function() {
	// Step 1
	$('form#loginForm').submit(function(e){
		e.preventDefault();
		app.login();
		return false;
	});
	
	
	if(app.myid == null) {
		$.mobile.changePage($("#splash"));
	}
});

