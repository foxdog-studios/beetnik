class @BeatsVisualisation
  constructor: (selector) ->
    @cvs = $(selector)[0]

    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (beats, start, end) ->
    @cvs.width = @cvs.width

    @ctx.fillStyle = '#FFFFFF'

    window = end - start
    pixelsPerSecond = @cvs.width / window

    for beat in beats
      continue if beat < start
      break if beat > end
      x = Math.round((beat - start) * pixelsPerSecond)
      @ctx.fillRect(x, 0, 1, Math.round(@cvs.height / 12))

