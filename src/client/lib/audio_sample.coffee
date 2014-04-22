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

  tryPlay: ->
    return unless @buffer?
    @source = @_ctx.createBufferSource()
    @source.buffer = @buffer
    @source.connect @_ctx.destination
    @source.start 0
    @playing = true

  stop: ->
    return unless @source?
    @source.stop 0
    @playing = false


class @UrlAudioSample extends AbstractAudioSample
  constructor: (@name) ->
    super

  loadAudio: (@_ctx, callback) ->
    loadAudioFromUrl "/#{@name}", (response) =>
      @_ctx.decodeAudioData response, (buffer) =>
        @buffer = buffer
        callback(@)

class @ArrayBufferAudioSample extends AbstractAudioSample
  constructor: (@arrayBuffer) ->
    super

  loadAudio: (@_ctx, callback) ->
    @_ctx.decodeAudioData @arrayBuffer, (buffer) =>
      @buffer = buffer
      callback(@)

