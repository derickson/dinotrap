var map, playerMarker;

App.Geo = Ember.Object.create({
	status: "Inactive",
	lat: 0.0,
	lon: 0.0,
	accuracy: 0.0
});



App.wid = null;
App.outsideGameZoneWarning = false;
App.startGeo = function() {
	
	console.log("startGeo");
	if (navigator.geolocation) {
			
			App.Geo.set('status','Pinging');
		
			App.wid = navigator.geolocation.watchPosition(
				function(position) {
					var lat = position.coords.latitude;
					var lon = position.coords.longitude;
					var acc = position.coords.accuracy;
					
					if(lon < -77.59 || lon > -76.65 || lat > 39.21 ||  lat < 38.60 ) {
						// outside of game zone
						lat = 38.9094;
						lon = -77.0426; 
						acc = 1;
						if(! App.outsideGameZoneWarning){
							alert ("You are outside Washington D.C., so I am placing you at Dupont Circle.");
							App.outsideGameZoneWarning = true;
						}
					}
					
					
					if( acc > 200) {
						App.Geo.set('status','Waiting for Accuracy');
					} else {
						navigator.geolocation.clearWatch( App.wid );
						App.wid = null;
					    
						App.Geo.set('status','Stopped');
						map ?  App.updatePlayerPositionAcc(lat, lon, acc) : App.startMap(lat, lon, acc);
					}
					
					
				},
				function(msg) {
					var message = 'LocError: '+ msg;
					console.log(message);
					App.Geo.set('status', message);
				},
				
				{
					enableHighAccuracy: true,
					maximumAge: 10000,
					timeout: 5000
				}
				
			);		
	} else {
		console.log('GeoLocation not supported');
		App.Geo.set('status','GeoLocation not supported');
	}
};


App.adjustMapSize = function() {
	
	//$('#map_canvas').css('height', 10 ).css('width', 10);
	
	var text = "";
	
	text += "window.screen.width: " + window.screen.width + "\n";
	text += "window.screen.height: " + window.screen.height + "\n";
	
	
	text += "d.dE.clientWidth: " + document.documentElement.clientWidth + "\n";
	text += "d.dE.clientHeight: " + document.documentElement.clientHeight + "\n";
	
	//alert(text);
	
	var width =  document.documentElement.clientWidth;
	var height = Math.min( window.screen.height, document.documentElement.clientHeight);
	//var width =  document.documentElement.clientWidth;
	//var height = document.documentElement.clientHeight;
	
	$('#map_canvas').css('height', height ).css('width', width);
	
    window.top.scrollTo(0, 1);
	
    var latlng = new google.maps.LatLng(App.Geo.get('lat'),  App.Geo.get('lon'));
	map && map.setCenter( latlng );
	
	
	//App.resizingFlag = false;
	
};





//App.resizingFlag = true;
App.startMap = function(lat, lon, acc) {
	console.log("startMap");
	
	App.Geo.set('lat', lat);
	App.Geo.set('lon', lon);
	App.Geo.set('accuracy', acc);
	
	var supportsOrientationChange = "onorientationchange" in window,
	    orientationEvent = supportsOrientationChange ? "orientationchange" : "resize";

	window.addEventListener(orientationEvent, function(e) {
		//if (!App.resizingFlag ) {
		//	App.resizingFlag = true;
		//	setTimeout(function(){ 
		//		App.resizingFlag = false; 
				App.adjustMapSize();
		//	}, 100);
			
		//}
	}, false);
	
	
	App.adjustMapSize();
	
    var latlng = new google.maps.LatLng(lat, lon);
	
	var myOptions = {
	      	center: latlng,
	      	zoom: 16,
	      	mapTypeId: google.maps.MapTypeId.ROADMAP,
	      	streetViewControl: false,
	      	mapTypeControl: false,
			disableDefaultUI: true,
			disableDoubleClickZoom: true,
			scaleControl: false,
			zoomControl: false,
			/*zoomControlOptions: { 
				position: google.maps.ControlPosition.RIGHT_BOTTOM ,
				style: google.maps.ZoomControlStyle.SMALL
			},	*/
		    styles : [
			  {
			    stylers: [
			      { visibility: "off" }
			    ]
			  },{
			    featureType: "landscape",
			    stylers: [
			      { visibility: "on" },
			      { invert_lightness: true }
			    ]
			  },{
			    featureType: "road",
			    stylers: [
			      { visibility: "on" },
			      { lightness: -41 },
			      { saturation: -79 },
			      { hue: "#9900ff" }
			    ]
			  },{
			    featureType: "transit",
			    stylers: [
			      { visibility: "on" }
			    ]
			  },{
			  }
			]
	      };
	

	
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	
	
	playerMarker = new MarkerWithLabel({
		   position: new google.maps.LatLng(lat,lon),
		   icon: "/images/j.png",
	       map: map,
	       labelContent: "Login to Play",
	       labelAnchor: new google.maps.Point(40, 0),
	       labelClass: "notloggedin", // the CSS class for the label
	       labelStyle: {opacity: 0.75},
		   clickable: false
	     });
	
	google.maps.event.addListener(map, 'dragend', function() { 
		var pos = map.getCenter();
		App.updatePlayerPosition(pos.lat(), pos.lng()); 
	});
	
};

App.newPlayerName = function(name) {
	playerMarker.setMap(null);
	playerMarker = new MarkerWithLabel({
		   position: new google.maps.LatLng(App.Geo.get('lat'),App.Geo.get('lon')),
		   icon: "/images/j.png",
	       labelContent: name,
	       labelAnchor: new google.maps.Point(40, 0),
	       labelClass: "playerlabel", // the CSS class for the label
	       labelStyle: {opacity: 0.75},
		   clickable: false,
	       map: map,
	     });
};

App.updatePlayerPosition = function(lat, lon) {
	App.updatePlayerPositionAcc(lat, lon, -1)
};

App.updatePlayerPositionAcc = function(lat, lon, acc) {
	//console.log("updatePlayerPosition");
	App.Geo.set('lat', lat);
	App.Geo.set('lon', lon);
	App.Geo.set('accuracy', acc);
    var latlng = new google.maps.LatLng(lat, lon);
	map && map.panTo( latlng );
	playerMarker.setPosition(latlng);
	
	App.notifyServerOfPostion(App.Player.get('name'), App.Player.get('id'), lat, lon);
};

App.otherPlayers = {};
App.otherPlayer = function(data) {
	if(App.Player.id !== data.id) {
		if( ! App.otherPlayers[data.id] ) {
			App.otherPlayers[data.id] = data;
			App.otherPlayers[data.id].marker = new MarkerWithLabel({
				   position: new google.maps.LatLng(data.lat,data.lon),
				   icon: "/images/j-bw.png",
			       labelContent: data.name,
			       labelAnchor: new google.maps.Point(40, 0),
			       labelClass: "playerlabel", // the CSS class for the label
			       labelStyle: {opacity: 0.75},
				   clickable: false,
			       map: map,
			     });
		} else {
			var pMarker = App.otherPlayers[data.id].marker;
			App.otherPlayers[data.id].lat = data.lat;
			App.otherPlayers[data.id].lon = data.lon;
		    var latlng = new google.maps.LatLng(data.lat, data.lon);
			pMarker.setPosition(latlng);
		}
	}
	 
};


App.placeDate = function() {
	var date = new Date();
	return Date.UTC(1900 + date.getYear(), date.getMonth(), date.getDate(),date.getHours(),date.getMinutes(),date.getSeconds(),date.getMilliseconds());
};

App.dirtyList = {};
App.dinos = {};
App.clearDirtyList = function() {
	for(var key in App.dirtyList) { 
		delete App.dirtyList[key]; 
	}
};
App.markDinosForDelete = function() {
	App.clearDirtyList();
	for(var key in App.dinos) {
		App.dirtyList[key] = {dirty:true};
	}
};
App.removeFromDirtyList = function(key) {
	App.dirtyList[key] && delete App.dirtyList[key];
};
App.deleteMarkedDinos = function() {
	for(var key in App.dirtyList) {
		App.dinos[key] && App.dinos[key].marker.setMap(null);
		App.dinos[key] && delete App.dinos[key];
		
	}
	App.clearDirtyList();
};



App.placeDino = function(data) {
	
	App.removeFromDirtyList(data.id);
	
	if(! App.dinos[data.id]) {
		//new dino
		App.dinos[data.id] = data;
		App.dinos[data.id].placeDate = App.placeDate();
		App.dinos[data.id].marker = new google.maps.Marker({
			clickable: false,
			icon: "/images/trex.png",
			position: new google.maps.LatLng(data.lat,data.lon),
			map: map
		});
	} else {
		//existing dino
		dMarker = App.dinos[data.id].marker;
		dMarker.placeDate = App.placeDate();
		dMarker.lat = data.lat;
		dMarker.lon = data.lon;
		var latlng = new google.maps.LatLng(data.lat, data.lon);
		dMarker.setPosition(latlng);
	}
};

App.traps = {};
App.clearCircles = function() {
	for(var key in App.traps) { 
		App.traps[key].circle.setMap(null);
		delete App.traps[key]; 
	}
};
App.drawTrap = function(trap) {
	var id = trap.survivorGuid ? trap.survivorGuid : trap.survivorId;
	App.traps[trap.guid] = trap;
	
	var split = trap.location.split(",");
	var color = id === App.Player.get('id')  ? "#0000EE" : "#EE00EE";
	
	var circleOptions = {
	      strokeColor: color,
	      strokeOpacity: 0.8,
	      strokeWeight: 2,
	      fillColor: color,
	      fillOpacity: 0.35,
	      map: map,
	      center: new google.maps.LatLng(split[0], split[1]),
	      radius: trap.distance * 1609.344 // meters in a mile
	    };
	App.traps[trap.guid].circle = new google.maps.Circle(circleOptions);
};


App.handleDinos = function(data) {
	App.markDinosForDelete();
	
	//App.clearEverything();
	
	$.each( data.dinos, function(i, m) {
		App.placeDino(m);
	});
	
	
	App.clearCircles();
	$.each( data.traps, function(i, t) {
		App.drawTrap(t);
	});
	
	App.deleteMarkedDinos();
};
