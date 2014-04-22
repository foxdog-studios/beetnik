@loadAudio = (url, callback) ->
  request = new XMLHttpRequest
  request.open 'GET', url, true
  request.responseType = 'arraybuffer'
  request.onload = () ->
    callback(request.response)
  request.send()

class @AudioSample
  constructor: (@_ctx, name, @callback, options) ->
    @autoplay = options?.autoplay or false
    @loop = options?.loop or false
    @playing = false
    @_loadAudio(name)

  _loadAudio: (name) ->
    loadAudio "/#{ name }", (response) =>
      @_ctx.decodeAudioData response, (buffer) =>
        console.log 'Loaded', name
        @buffer = buffer
        @tryPlay() if @autoplay
        @callback(@)

  tryPlay: ->
    return unless @buffer?
    @source = @_ctx.createBufferSource()
    @source.loop = @loop
    @source.buffer = @buffer
    @source.connect @_ctx.destination
    @source.start 0
    @playing = true

  stop: ->
    return unless @source?
    @source.stop 0
    @playing = false

