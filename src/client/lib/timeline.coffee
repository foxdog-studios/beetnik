class @Timeline
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (time, endTime) ->
    xPixelsPerSecond = @cvs.width / endTime
    xPixels = Math.round(xPixelsPerSecond * time)
    # clear the canvas
    @cvs.width = @cvs.width
    @ctx.fillStyle = "#00FF00"
    @ctx.fillRect(xPixels, 0, 2, @cvs.height)

