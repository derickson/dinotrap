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

app.mlservicehost = "localhost";
app.mlserviceport = 9056;

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



app.post('/ReceiveJSON', function(req, res){
  console.log(req.body);
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
				console.log("I placed a trap: "+trapId+" at location: "+location);
			})
		});
		
   	});

});

// ######## Launch

app.listen(9060, function(){
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
});
