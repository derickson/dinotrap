

google.load("earth", "1");



var ge;

var dinoapp = {
	
	init: function() {
		google.earth.createInstance('map3d', dinoapp.initCB, dinoapp.failureCB);
	},
	
	initCB: function(instance) {
	   ge = instance;
	   ge.getWindow().setVisibility(true);
	
		dinoapp.loadKML();
	
		// Get the current view.
		var lookAt = ge.getView().copyAsLookAt(ge.ALTITUDE_RELATIVE_TO_GROUND);

		// Set new latitude and longitude values.
		lookAt.setLatitude(38.9103);
		lookAt.setLongitude(-77.0192);
		lookAt.setRange(25000.0);

		// Update the view in Google Earth.
		ge.getView().setAbstractView(lookAt);
	
		//setInterval(dinoapp.refreshKML, 5000);
	
	},
	
	refereshKML: function() {
		dinoapp.removeFeatures();
		dinoapp.loadKML();
	},
	
	loadKML: function() {
		var link = ge.createLink('');
		var href = 'https://69.143.171.59:9056/status.kml'; //69.143.171.59
		link.setHref(href);
		link.setRefreshMode(ge.REFRESH_ON_INTERVAL);
		link.setRefreshInterval(5);

		var networkLink = ge.createNetworkLink('');
		networkLink.set(link, true, false); // Sets the link, refreshVisibility, and flyToView
		ge.getFeatures().appendChild(networkLink);
	},
	
	removeFeatures: function () {
		var features = ge.getFeatures();
		while (features.getFirstChild())
		   features.removeChild(features.getFirstChild());
		console.log("Removed");
	},
	
	failureCB: function(errorCode) {
		console.log(errorCode);
	}


};



	
	





google.setOnLoadCallback(dinoapp.init);