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

  tryPlay: (offset, gain, _when = 0) ->
    return unless @buffer?
    @source = @_ctx.createBufferSource()
    @source.buffer = @buffer
    gainNode = @_ctx.createGain()
    if gain?
      gainNode.gain.value = gain
    @source.connect gainNode
    gainNode.connect @_ctx.destination
    if $.isNumeric(offset)
      @source.start _when, offset
    else
      @source.start _when
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
      if callback?
        callback(@)

