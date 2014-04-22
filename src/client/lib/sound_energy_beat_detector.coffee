class @SoundEnergyBeatDetector
  SAMPLE_RATE = 44100

  constructor: ->

  detectBeats: (pcmAudioData, previousAverageEnergyCoefficient,
                samplesPerInstantEnergy, numberOfPreviousSamples) ->
    beats = []

    previousSamples = []

    previousSamplesIndex = 0

    sampleSum = 0

    for pcm, i in pcmAudioData
      sampleSum += Math.pow(pcm, 2)
      if i % samplesPerInstantEnergy == 0
        if previousSamples.length < numberOfPreviousSamples
          previousSamples.push sampleSum
        else
          previousSamplesSum = 0
          for previousSample in previousSamples
            previousSamplesSum += previousSample
          previousSamplesAverage = \
              previousSamplesSum / numberOfPreviousSamples
          threshold = previousAverageEnergyCoefficient * previousSamplesAverage
          if sampleSum > threshold
            # It's a beat!
            #
            # Convert it to seconds and save it.
            beats.push i / SAMPLE_RATE

          previousSamples.splice(previousSamplesIndex, 1, sampleSum)

        previousSamplesIndex++
        if previousSamplesIndex >= numberOfPreviousSamples
          previousSamplesIndex = 0
        sampleSum = 0
    beats

