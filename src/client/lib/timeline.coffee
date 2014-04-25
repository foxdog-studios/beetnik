class @Timeline
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (time, start, end) ->
    @cvs.width = @cvs.width
    if time < start or time > end
      return
    window = end - start
    xPixelsPerSecond = @cvs.width / window
    xPixels = Math.round(xPixelsPerSecond * (time - start))
    # clear the canvas
    @ctx.fillStyle = "#886666"
    @ctx.fillRect(xPixels - 1, 0, 4, @cvs.height)
    @ctx.fillStyle = "#FF0000"
    @ctx.fillRect(xPixels, 0, 2, @cvs.height)

