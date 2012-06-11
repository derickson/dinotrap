var map, playerMarker;

var App = Em.Application.create();
var util = {};

App.Player = Ember.Object.create({
	points: 0,
	traps: "infinite",
	myname: null,
	myid: null
});

App.Geo = Ember.Object.create({
	status: "Inactive",
	lat: 0.0,
	lon: 0.0,
	accuracy: 0.0
});

App.Comms = Ember.Object.create({
	status: "Inactive"
});

App.ping = {
	init: function() { $("span#ping").hide(); },
	show: function() { $("span#ping").show().fadeOut(2000); }
};

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
						App.Geo.set('lat', lat);
						App.Geo.set('lon', lon);
						App.Geo.set('accuracy', acc);
						map ?  App.updatePlayerPosition(lat, lon) : App.startMap(lat, lon);
					}
					
					

					
					App.ping.show();
					
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

App.startSocket = function() {
	console.log("startSocket");
	App.Comms.set('status',"Attempting");
	
	App.socket = io.connect('/');

	App.socket.on('connect', function() {
		
		
		$('#actionButton').show();
		
		App.socket.on('connect_failed', function () {
			App.Comms.set('status', "Failed");
		})
		
		App.socket.on("serverResponse", function() {
			App.Comms.set('status', "Connected");
		});
		
	});
	
	App.socket.on("login-accepted", function(data) {
		App.Player.set('myname', data.name);
		App.Player.set('myid', data.id);
		App.Player.set('points', data.points);
	});
};

App.loginFlag = false;
App.login = function () {
	if (!App.loginFlag) {	
		App.loginFlag = true;
		setTimeout(function(){ App.loginFlag = false; }, 100);
		
		var name = "dave"; //$("input#name").val().toLowerCase();
		var reg	 = /^[\w\s\d]+$/
		if( reg.test(name) ) {
			App.socket.emit('login', {"name": name});
		} else {
			alert("Please enter a valid name.")
		}
		
	}
};

util.adjustMapSize = function() {
	
	var text = "";
	
	text += "window.screen.width: " + window.screen.width + "\n";
	text += "window.screen.height: " + window.screen.height + "\n";
	
	
	text += "d.dE.clientWidth: " + document.documentElement.clientWidth + "\n";
	text += "d.dE.clientHeight: " + document.documentElement.clientHeight + "\n";
	
	//alert(text);
	
	var width =  document.documentElement.clientWidth;
	var height = Math.min( window.screen.height, document.documentElement.clientHeight);
	
	$('#map_canvas').css('height', height ).css('width', width);
	
    window.top.scrollTo(0, 1);
	
    var latlng = new google.maps.LatLng(App.Geo.get('lat'),  App.Geo.get('lon'));
	map && map.setCenter( latlng );
	
};

App.startMap = function(lat, lon) {
	console.log("startMap");
	
	var supportsOrientationChange = "onorientationchange" in window,
	    orientationEvent = supportsOrientationChange ? "orientationchange" : "resize";

	window.addEventListener(orientationEvent, function(e) {
	    util.adjustMapSize();
	}, false);
	
	/*window.addEventListener(onresize, function(e) {
		console.log("onresize");
	    util.adjustMapSize();
	}, false);*/
	
	util.adjustMapSize();
	
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
	
	
	playerMarker = new google.maps.Marker({
		position: new google.maps.LatLng(lat,lon), 
		icon: "/images/j.png",
		clickable: false,
		map: map 
	});
	
	google.maps.event.addListener(map, 'dragend', function() { 
		var pos = map.getCenter();
		App.updatePlayerPosition(pos.lat(), pos.lng()); 
	});
	
};



App.updatePlayerPosition = function(lat, lon) {
	console.log("updatePlayerPosition");
	App.Geo.set('lat', lat);
	App.Geo.set('lon', lon);
    var latlng = new google.maps.LatLng(lat, lon);
	map && map.panTo( latlng );
	playerMarker.setPosition(latlng);
};


App.recenterFlag = false;
App.recenterClick = function() {
	if (!App.recenterFlag && App.wid === null) {
		App.recenterFlag = true;
		setTimeout(function(){ App.recenterFlag = false; }, 100);
		App.startGeo();
	}
};


$(document).ready(function() {
	
	
	App.ping.init();
	App.startGeo();
	App.startSocket();
	
});