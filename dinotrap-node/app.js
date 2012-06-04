/**
 * DinoTrap
 * A localized game involving dinosaurs, traps, etc ...
 */

// ######## Module dependencies.

var express = require('express');
var app = module.exports = express.createServer();
var io = require('socket.io').listen(app);
var https = require('https');
var url = require('url');

// ######## Configuration

app.map = {
	toRad: function(number) {
		return number * Math.PI / 180.0
	},
	
	
	
	calcDistance: function (lat1, lon1, lat2, lon2) {
		var R = 3956.6; // miles
		var dLat = app.map.toRad(lat2-lat1);
		var dLon = app.map.toRad(lon2-lon1).toRad();
		var lat1 = app.map.toRad(lat1);
		var lat2 = app.map.toRad(lat2);

		var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
		        Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2); 
		var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
		var d = R * c;
		return d;
	}
};

app.mlservicehost = "localhost";
app.mlserviceport = 9056;
app.time = null;

app.configure(function(){
  app.use(express.bodyParser());
  app.use(express.static(__dirname + '/public'));
});

app.configure('development', function(){
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});

app.configure('production', function(){
  app.use(express.errorHandler());
});



app.post('/receiveAlert', function(req, res){
  //console.log(req.body);
    io.sockets.emit("trap-spring", req.body)
  res.send("ok");
});

// ######## ML Interaction

app.mlNewUser= function(name, cb) {
	var getOptions = {
	      host: app.mlservicehost,
	      port: app.mlserviceport,
	      path: "/survivor/"+name+"?format=json",
	      method: 'PUT'
	    };
	
	var req = https.request(getOptions, function(res){
        //console.log('STATUS: ' + res.statusCode);
        //console.log('HEADERS: ' + JSON.stringify(res.headers));
        res.setEncoding('utf-8');


        res.on('data',function(chunk){
				var jsonChunk = JSON.parse(chunk);
                cb(jsonChunk.guid, jsonChunk.points);
        });
    });

    req.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });

    req.end();
};

app.mlPlaceTrap= function(data, cb) {
	
	//console.log(data);
	
	var getOptions = {
	      host: app.mlservicehost,
	      port: app.mlserviceport,
	      path: "/survivor/" +data.id+ "/trap/" +data.lat+ "," +data.lon+ "?format=json",
	      method: 'PUT'
	    };
	
	var req = https.request(getOptions, function(res){
        //console.log('STATUS: ' + res.statusCode);
        //console.log('HEADERS: ' + JSON.stringify(res.headers));
        res.setEncoding('utf-8');


        res.on('data',function(chunk){
				var jsonChunk = JSON.parse(chunk);
                cb(jsonChunk.guid, jsonChunk.survivorGuid, jsonChunk.location, jsonChunk.distance);
        });
    });

    req.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });

    req.end();
};

app.mlDCDinos = function() {
	var getOptions = {
	      host: app.mlservicehost,
	      port: app.mlserviceport,
	      path: "/poll/dc?format=json",
	      method: 'GET'
	    };
	
	var message = "";
	
	var req = https.request(getOptions, function(res){
        //console.log('STATUS: ' + res.statusCode);
        //console.log('HEADERS: ' + JSON.stringify(res.headers));
        res.setEncoding('utf-8');


		//var data = res.body;
		//console.log(data);

    //    res.on('data',function(chunk){
	//		message += chunk;
			//	console.log("CHUNK: " +chunk);
			//	var jsonChunk = JSON.parse(chunk);
            //    console.log(jsonChunk);
			//	//io.sockets.emit('dinos',jsonChunk);
    //    });

		res.on('end', function() {
	//		var dinos = JSON.parse(message);
	//		io.sockets.emit('dinos', dinos);
			io.sockets.emit("newDinosAvailable")
		});

    });

    req.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });

    req.end();
};

app.mlNearMe = function(data, cb) {
	var path = "/survivor/"+data.id+"/nearMe/"+data.lat+","+data.lon+"?format=json";
	
	var getOptions = {
	      host: app.mlservicehost,
	      port: app.mlserviceport,
	      path: path,
	      method: 'GET'
	    };
	var message = "";
	
	
	var req = https.request(getOptions, function(res){
		
		console.log("start message "+message);
		
        res.setEncoding('utf-8');

    	res.on('data',function(chunk){
			var jsonChunk = JSON.parse(chunk);
			cb(jsonChunk);
        });

    });

    req.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });

    req.end();
};


// ######## Socket.IO



io.sockets.on('connection', function (socket) {
	
	socket.on('login', function (data) {
	    socket.set('name', data.name, function() {
			app.mlNewUser(data.name, function(id, points) {
				//console.log("id: "+id+" points: "+points);
				socket.join(id);
				socket.to(id).emit("login-accepted", {
					"name": data.name, 
					"id": id, 
					"points": points}
				)
			});
		});
		
		
		socket.on('placeTrap', function(data) {
			app.mlPlaceTrap(data, function (trapId, survivorId, location, distance) {
				io.sockets.emit("trapPlaced", {"trapId":trapId, "survivorId": survivorId, "location": location, "distance": distance});
				console.log("I placed a trap: "+trapId+" at location: "+location);
			})
		});
		
		socket.on('nearMe', function(data) {
			console.log("nearMe Request");
			app.mlNearMe(data, function(nearData) {
				io.sockets.to(data.id).emit("thingsNearYou", nearData);
			});
		});
		
   	});

});

// ######## Launch

app.listen(9060, function(){
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
  app.timer = setInterval(app.mlDCDinos, 120000);

});
