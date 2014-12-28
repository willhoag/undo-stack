'use strict'

Chunk = require('../src/Chunk')

describe 'Chunk', ->

  # instantiate service
  chunk = null
  historyObject = null
  makeHistoryObject = null

  spy1 = null
  spy2 = null
  spy3 = null

  beforeEach ->

    spy1 = sinon.spy()
    spy2 = sinon.spy()
    spy3 = sinon.spy()

    makeHistoryObject = (name, undo, redo) ->
      name: name
      undo: undo
      redo: redo

    historyObject = makeHistoryObject('name', spy1, spy2)

    chunk = new Chunk

  describe 'instantiation', ->

    it 'should define the proper instance variables', ->
      expect(chunk.stack).to.exist
      expect(chunk.name).to.exist
      expect(chunk.stack).to.be.an.instanceof Array

    it "should set name to parameter if supplied", ->
      chunk = new Chunk('nameForFun')
      expect(chunk.name).to.equal 'nameForFun'

  describe 'method', ->
    describe "add", ->
      it "should add step to stack", ->
        expect(chunk.stack.length).to.equal 0
        chunk.add(historyObject)
        expect(chunk.stack.length).to.equal 1
        chunk.add(historyObject)
        expect(chunk.stack.length).to.equal 2

    describe "undo", ->
      it "should call undo for every item in a stack of 3", ->
        for i in [1..3]
          chunk.add(historyObject)
        chunk.undo()
        expect(spy1.callCount).to.equal 3

      it "should call undo for every item in a stack of 5", ->
        for i in [1..5]
          chunk.add(historyObject)
        chunk.undo()
        expect(spy1.callCount).to.equal 5

      it "should call undos in reverse order of stack", ->
        chunk.add(makeHistoryObject('name', spy1, spy1))
        chunk.add(makeHistoryObject('name', spy2, spy2))
        chunk.add(makeHistoryObject('name', spy3, spy3))
        chunk.undo()
        spy1.should.have.been.calledAfter(spy2)
        spy2.should.have.been.calledAfter(spy3)
        spy3.should.have.been.calledBefore(spy2, spy1)

    describe "redo", ->

      it "should call redo for every item in the stack", ->
        for i in [1..6]
          chunk.add(historyObject)
        chunk.redo()
        expect(spy2.callCount).to.equal 6
