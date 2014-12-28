class Chunk

  constructor: (name='chunk') ->
    @stack = []
    @name = name

  add: (step) ->
    @stack.push step

  undo: ->
    for step in @stack.reverse()
      step.undo()

  redo: ->
    for step in @stack
      step.redo()

module.exports = Chunk
