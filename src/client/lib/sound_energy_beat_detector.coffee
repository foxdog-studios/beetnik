class @SoundEnergyBeatDetector
  SAMPLE_RATE = 44100

  constructor: ->

  detectBeats: (pcmAudioData, previousEnergyVarianceCoefficient,
                previousAverageEnergyCoefficient,
                samplesPerInstantEnergy, numberOfPreviousSamples) ->
    beats = []
    energies = []
    averageEnergies = []
    maxEnergy = 0

    previousSamples = []

    previousSamplesIndex = 0

    sampleSum = 0

    for pcm, i in pcmAudioData
      sampleSum += Math.pow(pcm, 2)
      if i % samplesPerInstantEnergy == 0
        if sampleSum > maxEnergy
          maxEnergy = sampleSum
        currentTimeSeconds = i / SAMPLE_RATE
        energies.push [currentTimeSeconds, sampleSum]
        if previousSamples.length < numberOfPreviousSamples
          previousSamples.push sampleSum
        else
          previousSamplesSum = 0
          for previousSample in previousSamples
            previousSamplesSum += previousSample
          previousSamplesAverage = \
              previousSamplesSum / numberOfPreviousSamples

          sumOfDifferencesFromAverage = 0
          for previousSample in previousSamples
            sumOfDifferencesFromAverage += \
              Math.pow(previousSample - previousSamplesAverage, 2)
          previousSamplesVariance = \
              sumOfDifferencesFromAverage / numberOfPreviousSamples

          v = previousSamplesVariance * previousEnergyVarianceCoefficient
          c = v + parseFloat(previousAverageEnergyCoefficient)
          threshold = c * previousSamplesAverage

          averageEnergies.push [currentTimeSeconds, threshold]

          if sampleSum > threshold
            # It's a beat!
            #
            # Convert it to seconds and save it.
            beats.push currentTimeSeconds

          previousSamples.splice(previousSamplesIndex, 1, sampleSum)

        previousSamplesIndex++
        if previousSamplesIndex >= numberOfPreviousSamples
          previousSamplesIndex = 0
        sampleSum = 0
    [beats, energies, averageEnergies, maxEnergy]

