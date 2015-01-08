class @SoundEnergyBeatDetector
  SAMPLE_RATE = 44100
  BEAT_MIN_DISTANCE_SAMPLES = 10
  MAX_DISTANCE_MULTIPLIER = 2

  MAX_SEARCH_WINDOW_SIZE = 3

  constructor: ->

  detectBeats: (pcmAudioData,
                previousEnergyVarianceCoefficient,
                previousAverageEnergyCoefficient,
                @_samplesPerInstantEnergy,
                @_numberOfPreviousEnergies) ->

    @maximumEnergies = []
    @_distanceInEnergyIndexBetweenBeats = []
    lastBeatIndex = 0
    @energies = []
    @averageEnergies = []
    @maxEnergy = 0
    @_maxCountIndex = 0
    @_maxBeatIndex = 0
    @_maxBeatValue = 0

    @variances = []

    previousEnergies = []

    previousEnergiesIndex = 0

    instantEnergySum = 0

    for pcm, i in pcmAudioData

      # Keep track of the current sum of square samples.
      instantEnergySum += pcm * pcm

      continue unless i % @_samplesPerInstantEnergy == 0

      # Keep track of the maximum instant energy in the audio data.
      if instantEnergySum > @maxEnergy
        @maxEnergy = instantEnergySum

      # The current time in seconds we are at in the audio data.
      currentTimeSeconds = i / SAMPLE_RATE

      # Save the current instant energy
      @energies.push [currentTimeSeconds, instantEnergySum]

      if previousEnergies.length < @_numberOfPreviousEnergies
        # We don't have enough instant energies yet to do the beat detection.
        previousEnergies.push instantEnergySum
      else
        # Calculate te average/mean energy in the previous energies.
        previousEnergiesSum = 0
        for previousEnergy in previousEnergies
          previousEnergiesSum += previousEnergy
        previousEnergiesAverage = \
            previousEnergiesSum / previousEnergies.length

        # Calulate the variance (average deviation from the mean) in the
        # previous energies.
        sumOfDifferencesFromAverage = 0
        for previousEnergy in previousEnergies
          difference = previousEnergy - previousEnergiesAverage
          sumOfDifferencesFromAverage += difference * difference
        previousEnergiesVariance = \
            sumOfDifferencesFromAverage / previousEnergies.length

        # Save our variance
        @variances.push [currentTimeSeconds, previousEnergiesVariance]

        # Calculate the threshold the current instant energy must be above
        # to be a potential candidate for a beat.
        v = previousEnergiesVariance * previousEnergyVarianceCoefficient
        c = v + previousAverageEnergyCoefficient
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
            @maximumEnergies.push currentTimeSeconds
            @_distanceInEnergyIndexBetweenBeats.push
              distance: distanceBetweenBeatIndexes
              energy: instantEnergySum
              index: currentIndex
              maximumEnergiesIndex: @maximumEnergies.length - 1

        # Remove oldest previous energy and replace it with the current
        # instant energy
        previousEnergies.splice(previousEnergiesIndex, 1, instantEnergySum)

      # Reset the index into the previous energies if necessary, such that
      # it acts like a circular buffer.
      previousEnergiesIndex++
      if previousEnergiesIndex >= @_numberOfPreviousEnergies
        previousEnergiesIndex = 0

      # Reset the instant energy
      instantEnergySum = 0

    @_calculateTempo()

    @beats = @maximumEnergies.slice(0)
    @_removeOutOfTimeBeats()
    @_addBeatsInGaps()


  _calculateTempo: ->
    maxDistanceBetwenBeats = @_numberOfPreviousEnergies \
      * MAX_DISTANCE_MULTIPLIER

    # These are buckets which we will use to count where the most beats landed
    beatDistanceCounts = []

    for i in [0..maxDistanceBetwenBeats]
      beatDistanceCounts.push
        count: 0
        beats: []

    # Fill the buckets, by counting the occurances of each distance betwee
    # the beats
    for data in @_distanceInEnergyIndexBetweenBeats
      distance = data.distance
      if distance < maxDistanceBetwenBeats
        beatDistanceCounts[distance].count++
        beatDistanceCounts[distance].beats.push data

    @_maxCountIndex = 0

    # Find the index of the distance that occurs the most
    maxCountSoFar = 0
    for beatDistanceCount, i in beatDistanceCounts
      if beatDistanceCount.count > maxCountSoFar
        maxCountSoFar = beatDistanceCount.count
        @_maxCountIndex = i
        @_principalBeat = beatDistanceCount

    divisor = maxCountSoFar

    if divisor == 0
      meanCount = 0
    else
      meanCount = (@_maxCountIndex * maxCountSoFar) / divisor

    @bpm = 60 / (meanCount * (@_samplesPerInstantEnergy / SAMPLE_RATE))

  _removeOutOfTimeBeats: ->
    # Find the most energetic of the principal beats
    maxMaximumEnergyIndex = 0
    maxMaximumEnergy = 0
    for beat in @_principalBeat.beats
      energy = @maximumEnergies[beat.maximumEnergiesIndex]
      if energy > maxMaximumEnergy
        maximumEnergiesIndex = beat.maximumEnergiesIndex
        maxMaximumEnergy = energy

    @_maxEnergyDistance =  \
      @_distanceInEnergyIndexBetweenBeats[maximumEnergiesIndex].distance

    lowerBound = @_maxEnergyDistance - MAX_SEARCH_WINDOW_SIZE
    upperBound = @_maxEnergyDistance + MAX_SEARCH_WINDOW_SIZE

    indexesToRemove = []
    distanceSoFar = 0
    distanceLength = @_distanceInEnergyIndexBetweenBeats.length - 1
    for i in [0..distanceLength]
      energy = @_distanceInEnergyIndexBetweenBeats[i]
      distance = energy.distance + distanceSoFar
      if distance < lowerBound or distance > upperBound
        distanceSoFar += energy.distance
        if distanceSoFar > @_maxEnergyDistance + MAX_SEARCH_WINDOW_SIZE
          distanceSoFar = 0
        indexesToRemove.push i
      else
        distanceSoFar = 0

    for i in [indexesToRemove.length - 1..0] by -1
      index = indexesToRemove[i]
      @beats.splice(index, 1)

  _addBeatsInGaps: ->
    @interpolatedBeats = []
    # Interpolate beats in the gaps between existing ones.
    secondsPerInstantEnegy = @_samplesPerInstantEnergy / SAMPLE_RATE
    lowerBound = (@_maxEnergyDistance - MAX_SEARCH_WINDOW_SIZE) \
      * secondsPerInstantEnegy
    upperBound = (@_maxEnergyDistance + MAX_SEARCH_WINDOW_SIZE) \
      * secondsPerInstantEnegy
    meanLength = @_maxEnergyDistance * secondsPerInstantEnegy
    beatsToInsert = []
    for i in [0..@beats.length - 2]
      beat = @beats[i]
      nextBeat = @beats[i + 1]
      gap = nextBeat - beat
      continue if gap >= lowerBound and gap <= upperBound
      subdivisions = gap / meanLength
      newBeats = []
      remainder = (subdivisions - Math.floor(subdivisions)) / subdivisions
      for j in [1..Math.floor(subdivisions)]
        newTime = beat + meanLength * j + meanLength * remainder
        if nextBeat - lowerBound < newTime
          continue
        newBeats.push newTime
      beatsToInsert.push
        index: i + 1
        beats: newBeats
    numberOfNewBeatsInserted = 0
    for b in beatsToInsert
      @beats.splice b.index + numberOfNewBeatsInserted, 0, b.beats...
      for beat in b.beats
        @interpolatedBeats.push beat
      numberOfNewBeatsInserted += b.beats.length






