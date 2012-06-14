
App.trapFlag = false;
App.trap = function () {
	if (!App.trapFlag) {	
		App.trapFlag = true;
		setTimeout(function(){ App.trapFlag = false; }, 100);
		
		App.placeTrap();
		
	}
};


App.loginFlag = false;
App.login = function () {
	if (!App.loginFlag) {	
		App.loginFlag = true;
		setTimeout(function(){ App.loginFlag = false; }, 100);
		
		
		$('#loginButton').hide();
		$('#loginPopup').show();
		
	}
};

App.loginGo = function() {
	var name = $("input#name").val().toLowerCase();
	App.attemptLogin(name, App.Geo.get('lat'), App.Geo.get('lon'));
};





App.recenterFlag = false;
App.recenterClick = function() {
	if (!App.recenterFlag && App.wid === null) {
		App.recenterFlag = true;
		setTimeout(function(){ App.recenterFlag = false; }, 100);
		//App.adjustMapSize();
		App.startGeo();
	}
};


$(document).ready(function() {
	
	App.startSocket();
	App.startGeo();
	
});