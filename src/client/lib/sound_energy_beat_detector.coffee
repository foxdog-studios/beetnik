class @SoundEnergyBeatDetector
  SAMPLE_RATE = 44100
  SAMPLES_PER_INSTANT_ENERGY = 2048
  NUMBER_OF_PREVIOUS_SAMPLES = 60

  THRESHOLD_CONSTANT = 1.3

  constructor: ->

  detectBeats: (pcmAudioData) ->
    beats = []

    previousSamples = []

    previousSamplesIndex = 0

    sampleSum = 0

    for pcm, i in pcmAudioData
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
            #
            # Convert it to seconds and save it.
            beats.push i / SAMPLE_RATE

          previousSamples.splice(previousSamplesIndex, 1, sampleSum)

        previousSamplesIndex++
        if previousSamplesIndex >= NUMBER_OF_PREVIOUS_SAMPLES
          previousSamplesIndex = 0
        sampleSum = 0
    beats
