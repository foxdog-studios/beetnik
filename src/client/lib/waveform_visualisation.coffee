class @WaveformVisualisation
  SAMPLES_PER_INSTANT_ENERGY = 2048
  NUMBER_OF_PREVIOUS_SAMPLES = 60

  THRESHOLD_CONSTANT = 1.3

  constructor: (selector, @pcmAudioData) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: ->
    @ctx.fillStyle = "#FF0000"
    data = @pcmAudioData

    previousSamples = []

    previousSamplesIndex = 0

    sampleSum = 0

    x = 0
    intervals = Math.ceil(@pcmAudioData.length / @cvs.width)
    for pcm, i in data
      # Draw the waveform
      if i % intervals == 0
        height = pcm * @cvs.height
        @ctx.fillRect(x, @cvs.height / 2, 1, height)
        x++

      sampleSum += Math.pow(pcm, 2)
      if i % SAMPLES_PER_INSTANT_ENERGY == 0
        if previousSamples.length < NUMBER_OF_PREVIOUS_SAMPLES
          previousSamples.push sampleSum
        else
          previousSamplesSum = 0
          for previousSample in previousSamples
            previousSamplesSum += previousSample
          previousSamplesAverage = \
              previousSamplesSum / NUMBER_OF_PREVIOUS_SAMPLES
          if sampleSum > THRESHOLD_CONSTANT * previousSamplesAverage
            # It's a beat!
            @ctx.fillStyle = "#0000FF"
            @ctx.fillRect(x, 0, 1, @cvs.height)
            @ctx.fillStyle = "#FF0000"

          previousSamples.splice(previousSamplesIndex, 1, sampleSum)

        previousSamplesIndex++
        if previousSamplesIndex >= NUMBER_OF_PREVIOUS_SAMPLES
          previousSamplesIndex = 0
        sampleSum = 0

