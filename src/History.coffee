'use strict'

Chunk = require('./Chunk')

# TODO -- Find out the author of original and give attribution
class History
  constructor: (spec={}) ->
    @log = spec.logger
    @stack = []
    @index = -1
    @isExecuting = false
    @isFrozen = true
    @isChunking = false
    @stackLimit = spec.limit

  _execute: (step, action) ->
    @_setExecuting(true)
    step[action]()
    @_setExecuting(false)

  _addToChunk: (step) ->
    last = @stack[@index]
    if last instanceof Chunk
      @log? "History add to chunk (#{last.name}): #{step.name}", step
      last.add(step)

  _addRegular: (step) ->
    @log? "History add: #{step.name}", step
    if @stack.length is @stackLimit then @stack.shift()
    @stack.push(step)

  _setExecuting: (bool) ->
    @isExecuting = !!bool

  do: (step) ->
    @add(step, true)

  add: (step, callOnAdd=false) ->
    if callOnAdd then step.redo()
    if not @isFrozen or @isExecuting then return @

    # if we are here after having called undo,
    # invalidate items higher on the stack
    @stack.splice @index + 1, @stack.length - @index

    if @isChunking
      @_addToChunk(step)
    else
      @_addRegular(step)

    # set the current @index to the end
    @index = @stack.length - 1
    return @

  undo: ->
    step = @stack[@index]
    if not step then return @
    @log? "History undo: #{step.name}", step
    @_execute step, "undo"
    @index -= 1
    return @

  redo: ->
    step = @stack[@index + 1]
    if not step then return @
    @log? "History redo: #{step.name}", step
    @_execute step, "redo"
    @index += 1
    return @

  # Clears the memory, losing all stored states.
  clear: ->
    prev_size = @stack.length
    @stack = []
    @index = -1
    return @

  setFrozen: (bool) ->
    @isFrozen = !!bool
    return @

  startChunk: (name) ->
    @add(new Chunk(name))
    @isChunking = true
    return @

  endChunk: ->
    @isChunking = false
    return @

  hasUndo: ->
    @index isnt -1

  hasRedo: ->
    @index < (@stack.length - 1)

module.exports = History
