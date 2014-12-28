var History = require('./dist/');

var history = new History({
	logger: console.log,
	limit: 200
});

var x = 5;

// To add a history step
history.add({
	name: 'plus 3',
	undo: function () { x -= 3; },
  redo: function () { x += 3; }
}); // x is still 5

// To add and call use .do()
// shortcut for .add(stackStepObj, true)
history.do({
	name: 'call on add',
	redo: function () { x += 3; },
	undo: function () { x -= 3; }
}); // x is 8 now

history
	.undo() // x is 5
	.redo(); // x is 8 again

// Chunks
history.startChunk('plus 7')
	.do({
		name: 'plus 2',
		undo: function () {x -= 2;},
		redo: function () {x += 2;}
	}) // x is 10
	.do({
		name: 'plus 5',
		undo: function () {x -= 5;},
		redo: function () {x += 5;}
	}) // x is 15
	.endChunk();

history
	.undo() // x is 8
	.redo(); // x is 15 again
