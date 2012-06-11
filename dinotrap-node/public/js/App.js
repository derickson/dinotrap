var App = Em.Application.create();
var util = {};

App.Player = Ember.Object.create({
	points: 0,
	traps: "infinite",
	name: null,
	id: null
});

