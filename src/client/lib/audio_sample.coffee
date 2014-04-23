@loadAudioFromUrl = (url, callback) ->
  request = new XMLHttpRequest
  request.open 'GET', url, true
  request.responseType = 'arraybuffer'
  request.onload = () ->
    callback(request.response)
  request.send()


class @AbstractAudioSample
  constructor:  ->
    @playing = false

  loadAudio: ->
    throw 'Load Audio must be implemented by subclass'

  tryPlay: (offset) ->
    return unless @buffer?
    @source = @_ctx.createBufferSource()
    @source.buffer = @buffer
    @source.connect @_ctx.destination
    @source.start 0, offset
    @playing = true

  stop: ->
    return unless @source?
    @source.stop 0
    @playing = false


class @ArrayBufferAudioSample extends AbstractAudioSample
  constructor: (@arrayBuffer) ->
    super

  loadAudio: (@_ctx, callback) ->
    @_ctx.decodeAudioData @arrayBuffer, (buffer) =>
      @buffer = buffer
      callback(@)

