var app = app || {};
app.socket = null;
app.myname = null;
app.myid = null;
app.mypoints = 0


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
					cb(lat,lon);
				},
				function(msg) {
					console.log('Error on myLocation: '+ msg);
				}
			);		
	} else {
		console.log('GeoLocation not supported');
	}
};

// Step 2: login form calls this when submitted
app.login = function() {
	var name = $("input#name").val().toLowerCase();
	var reg  = /^[\w\s\d]+$/
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
};


app.placeTrap = function() {
	
	if(app.socket !== null) {
		app.myLocation( function (lat, lon) {
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


/*
    socket.on('busses', function(data) {
        //clearPlacemarks();
        //setBusses(data);
        
        $('#map_canvas').gmap('clear', 'markers');
        $('#map_canvas').gmap('clear', 'overlays');
        
        
        $.each( data, function(i, m) {
            placeTrex(m);
        });
        
    });
*/
    


app.initMobileMap = function(lat,lon) {
    var position = ''+lat+', '+lon;

	app.pushModel();

    app.map = $('div#map_canvas').gmap(
        {
            'center': position, 
            'zoom': 14 ,
            'streetViewControl': false,
            'mapTypeControl': false,
			'disableDefaultUI': true,
			'disableDoubleClickZoom': true,
			'draggable': false
        });
    

	$( 'div#game' ).live( 'pageshow',function(event, ui){
	  $('div#map_canvas').gmap("refresh");
	});

    
	$.mobile.changePage($("#game"));
	
	
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
	//	$.mobile.changePage($("#splash"));
	}
});

