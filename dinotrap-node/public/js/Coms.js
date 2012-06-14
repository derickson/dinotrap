App.Comms = Ember.Object.create({
	status: "Inactive"
});


App.isLoggedIn = false;
App.startSocket = function() {
	console.log("startSocket");
	App.Comms.set('status',"Attempting");
	
	App.socket = io.connect('/');

	App.socket.on('connect', function() {
		
		console.log("comms established");
		
		App.Comms.set('status', "Connected");
		$('#loginButton').show();
		
		App.socket.on('connect_failed', function () {
			App.Comms.set('status', "Failed");
		})
		
		App.socket.on("login-accepted", function(data) {
			App.isLoggedIn = true;

			App.Player.set('name', data.name);

			App.newPlayerName(data.name);

			App.Player.set('id', data.id);
			App.Player.set('points', data.points);
			
			
			$('#trapButton').show();
			
			App.nearMe();
		});

		App.socket.on("otherPlayerPosition", function(data) {
			//console.log(data);
			App.otherPlayer(data);
		});
		
		App.socket.on("newDinosAvailable", function() {
			//console.log("newDinosAvailable");
			App.nearMe();
		});
		
		App.socket.on('thingsNearYou', function(data) {
			//console.log(data);
			//console.log("thingsNearMe");
			App.handleDinos(data);
		});
		
		App.socket.on("trapPlaced", function(data) {
			App.drawTrap(data);
		});
		
		App.socket.on("trap-spring", function(data) {
			//console.log(data);
			if(App.Player.get('id') === data.survivorId) {
				App.Player.set('points', data.points);
				alert("A dino walked into your trap.  You now have "+ data.points + " points!");
				App.nearMe();
			}

		});
		
	});
	

};

App.nearMe = function() {
	// get things near this client
	App.socket.emit("nearMe", {
		"name": App.Player.get('name'),
		"id": App.Player.get('id'),
		"lat": App.Geo.get('lat'),
		"lon": App.Geo.get('lon')
	});
};

App.attemptLogin = function(name, lat, lon) {
	var reg	 = /^[\w\d]+$/
	if( reg.test(name) && name.length < 10) {
		App.socket.emit('login', {"name": name, "lat": lat, "lon": lon});
		
		$('#loginPopup').hide();
	} else {
		alert("Please enter a valid name. Letters and Numbers.  Maximum 10 characters")
	}
};

App.notifyServerOfPostion = function(name, id, lat, lon){
	if(App.isLoggedIn) {
		//console.log( "name "+ name + " id " + id +  " lat " +  lat + " lon " + lon );
		App.socket.emit('myPosition', {"name": name, "id": id, "lat": lat, "lon": lon});
	}
};

App.placeTrap = function() {
	
	App.socket.emit("placeTrap", {
		"name": App.Player.get('name'),
		"id": App.Player.get('id'),
		"lat": App.Geo.get('lat'),
		"lon": App.Geo.get('lon')
	})
};