'use strict'

Chunk = require('../src/Chunk')
History = require('../src/History')

describe 'History', ->

  history = null
  chunk = null

  spy1 = null
  spy2 = null
  spy3 = null

  step = null
  step2 = null

  beforeEach ->
    history = new History
    chunk = new Chunk

    spy1 = sinon.spy()
    spy2 = sinon.spy()
    spy3 = sinon.spy()

    makeHistoryObject = (name, undo, redo) ->
      name: name
      undo: undo
      redo: redo

    step = makeHistoryObject('name', spy1, spy2)
    step2 = makeHistoryObject('name2', spy1, spy2)

  describe 'instantiation', ->

    it 'should define the proper instance variables', ->
      expect(history.stack).to.exist
      expect(history.index).to.exist
      expect(history.index).to.equal -1
      expect(history.isExecuting).to.exist
      expect(history.isFrozen).to.exist
      expect(history.isChunking).to.exist

  describe 'method', ->

    describe "_execute", ->

      it "should set isExecuting to true while executing", ->
        _setExecuting = sinon.stub history, '_setExecuting'
        history._execute(step, 'undo')
        _setExecuting.should.have.been.calledWith(true)
        _setExecuting.should.have.been.calledWith(false)

      it "should call action on the step object", ->
        history._execute(step, 'undo')
        spy1.should.have.been.called
        spy2.should.not.have.been.called
        history._execute(step, 'redo')
        spy2.should.have.been.called

      it "should set isExecuting to false when done", ->
        history._execute(step, 'undo')
        expect(history.isExecuting).to.be.false

    describe "_setExecuting", ->

      it "should set isExecuting to the truthy value of parameter", ->
        history._setExecuting(true)
        expect(history.isExecuting).to.be.true
        history._setExecuting(false)
        expect(history.isExecuting).to.be.false

    describe "add", ->

      it "should return this early if not active or isExecuting", ->
        history.setFrozen(false)
        history.add(step)
        expect(history.stack.length).to.equal 0

      it "should call _addToChunk if isChunking is true", ->
        _addToChunk = sinon.stub history, '_addToChunk'
        history.startChunk('chunkName')
        history.add(step)
        _addToChunk.should.have.been.calledWith(step)
        expect(history.stack.length).to.equal 1

      it "should call _addRegular if isChunking is false", ->
        _addRegular = sinon.stub history, '_addRegular'
        history.isChunking = false
        history.add(step)
        _addRegular.should.have.been.calledWith(step)

      it "should set the current index to the end", ->
        history.add(step)
        expect(history.index).to.equal history.stack.length - 1
        history.add(step)
        history.add(step)
        history.add(step)
        expect(history.index).to.equal history.stack.length - 1

      it "should return this", ->
        his = history.add(step)
        expect(his).to.equal history

      it "should call step.redo if 2nd parameter is true", ->
        history.add(step)
        spy2.should.not.been.called
        history.add(step2, true)
        spy2.should.have.been.called

    describe "do", ->
      it "should call add with the specified parameter and true", ->
        add = sinon.stub(history, 'add')
        history.do(step)
        add.should.have.been.calledWithExactly(step, true)

    describe "_addRegular", ->

      it "should add step to the stack", ->
        expect(history.stack.length).to.equal 0
        history.add(step)
        expect(history.stack[0]).to.equal step
        expect(history.stack.length).to.equal 1

      it "should enforce the stackLimit", ->
        history.stackLimit = 2
        expect(history.stack.length).to.equal 0
        history.add(step2)
        history.add(step)
        expect(history.stack.length).to.equal 2
        expect(history.stack[0]).to.equal step2
        history.add(step)
        expect(history.stack.length).to.equal 2
        expect(history.stack[0]).to.equal step

    describe "_addToChunk", ->

      it "should call last.add if last is an instance of Chunk", ->
        chunk = new Chunk
        add = sinon.stub(chunk, 'add')
        history.add(chunk)
        history._addToChunk(step)
        expect(add.callCount).to.equal 1
        history._addToChunk(step2)
        expect(add.callCount).to.equal 2

    describe "startChunk", ->

      it "should set chunking to the true", ->
        expect(history.isChunking).to.be.false
        history.startChunk('chunkName')
        expect(history.isChunking).to.be.true

      it "should call add with a new instance of Chunk", ->
        add = sinon.stub(history, 'add')
        history.startChunk('chunkName')
        add.should.have.been.calledWith sinon.match.instanceOf Chunk

      it "should instantiate Chunk with the specified name parameter", ->
        history.startChunk('chunkName')
        expect(history.stack[0].name).to.equal 'chunkName'
        history.endChunk()
        history.startChunk('name2')
        expect(history.stack[1].name).to.equal 'name2'

      it "should return this", ->
        his = history.startChunk('chunkName')
        expect(his).to.equal history

    describe "endChunk", ->

      it "should set isChunking to false", ->
        history.isChunking = true
        history.endChunk()
        expect(history.isChunking).to.be.false

    describe "undo", ->
      _execute = null
      beforeEach ->
        _execute = sinon.stub(history, '_execute')

      it "should return this early if there is no step previous index", ->
        his = history.undo()
        _execute.should.not.have.been.called
        expect(his).to.equal history

      it "should call _execute with the step and 'undo'", ->
        history.add(step)
        history.undo()
        _execute.should.have.been.calledWithExactly step, 'undo'

      it "should decrease the index by 1", ->
        history.add(step)
        history.add(step)
        history.add(step)
        history.add(step)
        expect(history.index).to.equal 3
        history.undo()
        history.undo()
        expect(history.index).to.equal 1
        history.undo()
        expect(history.index).to.equal 0

      it "should return this", ->
        history.add(step)
        his = history.undo()
        expect(his).to.equal history

    describe "redo", ->

      _execute = null
      beforeEach ->
        _execute = sinon.stub(history, '_execute')

      it "should return this early if there is no step next on the index", ->
        his = history.redo()
        _execute.should.not.have.been.called
        expect(his).to.equal history

      it "should call _execute with the step and 'redo'", ->
        history.add(step)
        history.undo()
        history.redo()
        _execute.should.have.been.calledWithExactly step, 'redo'

      it "should increase the index by 1", ->
        history.add(step)
        history.add(step)
        history.add(step)
        history.add(step)
        history.index = -1
        history.redo()
        history.redo()
        expect(history.index).to.equal 1
        history.redo()
        expect(history.index).to.equal 2
        history.redo()
        expect(history.index).to.equal 3

      it "should return this", ->
        history.add(step)
        his = history.redo()
        expect(his).to.equal history

    describe "clear", ->

      it "should clear the stack", ->
        history.add(step)
        history.add(step)
        expect(history.stack.length).to.equal 2
        history.clear()
        expect(history.stack.length).to.equal 0

      it "should reset the index to -1", ->
        history.add(step)
        history.add(step)
        history.clear()
        expect(history.index).to.equal -1

    describe "setFrozen", ->

      it "should set active to the truthy value of parameter", ->
        history.setFrozen(false)
        expect(history.isFrozen).to.be.false
        history.setFrozen(true)
        expect(history.isFrozen).to.be.true
        history.setFrozen(false)
        expect(history.isFrozen).to.be.false

      it "should return this", ->
        his = history.setFrozen(false)
        expect(his).to.equal history

    describe "hasUndo", ->

      it "should return true if there is an undo left", ->
        history.add(step)
        history.add(step)
        expect(history.hasUndo()).to.be.true
        history.undo()
        expect(history.hasUndo()).to.be.true

      it "should return false if there isn't an undo left", ->
        history.add(step)
        history.add(step)
        expect(history.hasUndo()).to.be.true
        history.undo()
        history.undo()
        expect(history.hasUndo()).to.be.false

    describe "hasRedo", ->

      it "should return true if there is a redo left", ->
        history.add(step)
        history.add(step)
        expect(history.hasRedo()).to.be.false
        history.undo()
        expect(history.hasRedo()).to.be.true
        history.undo()
        expect(history.hasRedo()).to.be.true

      it "should return false if there isn't a redo left", ->
        history.add(step)
        history.add(step)
        expect(history.hasRedo()).to.be.false
        history.add(step)
        expect(history.hasRedo()).to.be.false
