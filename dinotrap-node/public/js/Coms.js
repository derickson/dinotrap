App.Comms = Ember.Object.create({
	status: "Inactive"
});

App.ping = {
	init: function() { $("span#ping").hide(); },
	show: function() { $("span#ping").show().fadeOut(2000); }
};

App.isLoggedIn = false;
App.startSocket = function() {
	console.log("startSocket");
	App.Comms.set('status',"Attempting");
	
	App.socket = io.connect('/');

	App.socket.on('connect', function() {
		
		
		$('#loginButton').show();
		
		App.socket.on('connect_failed', function () {
			App.Comms.set('status', "Failed");
		})
		
		App.socket.on("serverResponse", function() {
			App.Comms.set('status', "Connected");
		});
		
	});
	
	App.socket.on("login-accepted", function(data) {
		App.isLoggedIn = true;
		App.Player.set('name', data.name);
		
		App.newPlayerName(data.name);
		
		App.Player.set('id', data.id);
		App.Player.set('points', data.points);
	});
	
	App.socket.on("otherPlayerPosition", function(data) {
		console.log(data);
		App.otherPlayer(data);
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