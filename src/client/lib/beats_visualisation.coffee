class @BeatsVisualisation
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (beats, maxTime) ->
    @cvs.width = @cvs.width

    @ctx.fillStyle = '#FFFFFF'

    pixelsPerSecond = @cvs.width / maxTime

    for beat in beats
      x = Math.round(beat * pixelsPerSecond)
      @ctx.fillRect(x, 0, 1, Math.round(@cvs.height / 12))

