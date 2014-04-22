class @WaveformVisualisation
  constructor: (selector, @pcmAudioData) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: ->
    @ctx.fillStyle = "#FF0000"

    x = 0
    intervals = Math.ceil(@pcmAudioData.length / @cvs.width)
    for pcm in @pcmAudioData by intervals
      # Draw the waveform
      height = pcm * @cvs.height
      @ctx.fillRect(x, @cvs.height / 2, 1, height)
      x++

