class @SoundEnergyBeatDetector
  SAMPLE_RATE = 44100
  BEAT_MIN_DISTANCE_SAMPLES = 10
  MAX_DISTANCE_MULTIPLIER = 2

  IMPULSE_TRAIN_SIZE = 108
  MAX_SEARCH_WINDOW_SIZE = 2

  constructor: ->

  detectBeats: (pcmAudioData,
                previousEnergyVarianceCoefficient,
                previousAverageEnergyCoefficient,
                samplesPerInstantEnergy,
                numberOfPreviousEnergies) ->
    maximumEnergies = []
    distanceInEnergyIndexBetweenBeats = []
    lastBeatIndex = 0
    energies = []
    @averageEnergies = []
    maxEnergy = 0

    previousEnergies = []

    previousEnergiesIndex = 0

    instantEnergySum = 0

    for pcm, i in pcmAudioData

      # Keep track of the current sum of square samples.
      instantEnergySum += Math.pow(pcm, 2)

      continue unless i % samplesPerInstantEnergy == 0

      # Keep track of the maximum instant energy in the audio data.
      if instantEnergySum > maxEnergy
        maxEnergy = instantEnergySum

      # The current time in seconds we are at in the audio data.
      currentTimeSeconds = i / SAMPLE_RATE

      # Save the current instant energy
      energies.push [currentTimeSeconds, instantEnergySum]

      if previousEnergies.length < numberOfPreviousEnergies
        # We don't have enough instant energies yet to do the beat detection.
        previousEnergies.push instantEnergySum
      else
        # Calculate the average/mean energy in the previous energies.
        previousEnergiesSum = 0
        for previousEnergy in previousEnergies
          previousEnergiesSum += previousEnergy
        previousEnergiesAverage = \
            previousEnergiesSum / numberOfPreviousEnergies

        # Calulate the variance (average deviation from the mean) in the
        # previous energies.
        sumOfDifferencesFromAverage = 0
        for previousEnergy in previousEnergies
          sumOfDifferencesFromAverage += \
            Math.pow(previousEnergy - previousEnergiesAverage, 2)
        previousEnergiesVariance = \
            sumOfDifferencesFromAverage / numberOfPreviousEnergies

        # Calculate the threshold the current instant energy must be above
        # to be a potential candidate for a beat.
        v = previousEnergiesVariance * previousEnergyVarianceCoefficient
        c = v + parseFloat(previousAverageEnergyCoefficient)
        threshold = c * previousEnergiesAverage

        # Save the threshold
        @averageEnergies.push [currentTimeSeconds, threshold]

        # Detect whether we have a beat.
        #
        # First check if we are above the threshold
        if instantEnergySum > threshold
          # Check if whether enough samples have passed to allow for another
          # beat
          currentIndex = @averageEnergies.length - 1
          distanceBetweenBeatIndexes = currentIndex - lastBeatIndex
          if distanceBetweenBeatIndexes > BEAT_MIN_DISTANCE_SAMPLES
            lastBeatIndex = currentIndex
            maximumEnergies.push currentTimeSeconds
            distanceInEnergyIndexBetweenBeats.push distanceBetweenBeatIndexes

        # Remove oldest previous energy and replace it with the current
        # instant energy
        previousEnergies.splice(previousEnergiesIndex, 1, instantEnergySum)

      # Reset the index into the previous energies if necessary, such that
      # it acts like a circular buffer.
      previousEnergiesIndex++
      if previousEnergiesIndex >= numberOfPreviousEnergies
        previousEnergiesIndex = 0

      # Reset the instant energy
      instantEnergySum = 0

    [bpm, convolution, beats] = @_calculateTempo(
                     distanceInEnergyIndexBetweenBeats,
                     numberOfPreviousEnergies,
                     samplesPerInstantEnergy)

    [maximumEnergies, energies, @averageEnergies, maxEnergy, bpm,
     convolution, beats]

  _calculateTempo: (distanceInEnergyIndexBetweenBeats,
                    numberOfPreviousEnergies,
                    samplesPerInstantEnergy) ->
    maxDistanceBetwenBeats = numberOfPreviousEnergies * MAX_DISTANCE_MULTIPLIER

    beatDistanceCounts = []
    for i in [0..maxDistanceBetwenBeats]
      beatDistanceCounts.push 0

    # Count the occurances
    for distance in distanceInEnergyIndexBetweenBeats
      if distance < maxDistanceBetwenBeats
        beatDistanceCounts[distance]++

    maxCountIndex = 0

    # Find the index of the distance that occurs the most
    maxCountSoFar = 0
    for beatDistanceCount, i in beatDistanceCounts
      if beatDistanceCount > maxCountSoFar
        maxCountSoFar = beatDistanceCount
        maxCountIndex = i

    # Calculate the average index from the neighbour with highest number of
    # occurances
    if maxCountIndex == beatDistanceCounts.length - 1
      neighbourIndex = maxCountIndex - 1
    else if maxCountIndex == 0
      neighbourIndex = maxCountIndex + 1
    else
      a = maxCountIndex - 1
      b = maxCountIndex + 1
      if beatDistanceCounts[a] > beatDistanceCounts[b]
        neighbourIndex = a
      else
        neighbourIndex = b

    neighbourCount = beatDistanceCounts[neighbourIndex]
    divisor = maxCountSoFar + neighbourCount

    if divisor == 0
      meanCount = 0
    else
      meanCount = \
        (maxCountIndex * maxCountSoFar + neighbourIndex * neighbourCount) \
        / divisor

    bpm = 60 / (meanCount * (samplesPerInstantEnergy / SAMPLE_RATE))

    [convolution, beats] = @_calculateConvolution(meanCount, maxCountIndex)

    [bpm, convolution, beats]

  _calculateConvolution: (meanCount, maxCountIndex) ->
    impulseTrain = []
    espace = 0
    impulseTrain.push 1
    for i in [1..IMPULSE_TRAIN_SIZE]
      if espace >= meanCount
        impulseTrain.push 1
        espace -= meanCount
      else
        impulseTrain.push 0
      espace += 1

    beatsConvolution = []
    convolution = []
    maxConv = 0
    maxConvIndex= 0

    for i in [0..@averageEnergies.length - IMPULSE_TRAIN_SIZE - 1]
      # init this here to zero
      beatsConvolution[i] = 0
      convolution[i] = [@averageEnergies[i][0], 0]
      for j in [0..IMPULSE_TRAIN_SIZE]
        convolution[i][1] += @averageEnergies[i+j][1] * impulseTrain[j]
      currentConv = Math.abs(convolution[i][1])
      if currentConv > maxConv
        maxConv = currentConv
        maxConvIndex = i

    # normalise
    ratio = 1 / maxConv
    for conv in convolution
      conv[1] *= ratio

    searchForMaxInWindow = (offset) ->
      maxSoFar = 0
      maxIndex = offset
      for i in [offset-MAX_SEARCH_WINDOW_SIZE..offset+MAX_SEARCH_WINDOW_SIZE]
        continue if i < 0
        break if i >= convolution.length
        conv = convolution[i][1]
        if conv > maxSoFar
          maxSoFar = conv
          maxIndex = i
      maxIndex

    # Where the maximum value of the convolution is where the principal beat
    # point is based. We will calculate the rest of the beats from there.
    beatsConvolution[maxConvIndex] = 1

    # We will search right from the prinicpal beat
    offsetIndexRight = maxConvIndex + maxCountIndex
    while offsetIndexRight < convolution.length \
        and convolution[offsetIndexRight][1] > 0
      localMaxPosition = searchForMaxInWindow(offsetIndexRight)
      beatsConvolution[localMaxPosition] = 1
      offsetIndexRight = localMaxPosition + maxCountIndex

    # Then search left from the principal beat
    offsetIndexLeft = maxConvIndex - maxCountIndex
    while offsetIndexLeft > 0
      localMaxPosition = searchForMaxInWindow(offsetIndexLeft)
      beatsConvolution[localMaxPosition] = 1
      offsetIndexLeft = localMaxPosition - maxCountIndex

    beats = []
    # Get the times for the beats, going through them in order, so the beat
    # timings will be sorted.
    for b, i in beatsConvolution
      if b > 0
        beats.push convolution[i][0]

    [convolution, beats]

