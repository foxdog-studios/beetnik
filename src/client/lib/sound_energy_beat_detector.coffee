class @SoundEnergyBeatDetector
  SAMPLE_RATE = 44100
  BEAT_MIN_DISTANCE_SAMPLES = 10000
  MAX_DISTANCE_MULTIPLIER = 32
  MAX_BPM_DETECTED = 300

  MAX_SEARCH_WINDOW_SIZE = 3
  MINIMUM_THRESHOLD = 1

  constructor: ->

  detectBeats: (pcmAudioData,
                previousEnergyVarianceCoefficient,
                @_previousAverageEnergyCoefficient,
                @_samplesPerInstantEnergy,
                @_numberOfPreviousEnergies,
                @_maxBpm) ->


    @_trackLength = pcmAudioData.length / SAMPLE_RATE

    @maximumEnergies = []


    @_beatMinDistanceSamples = @bpmToDistance(@_maxBpm)

    @_findBeats(pcmAudioData)
    @_previousAverageEnergyCoefficient -= 0.1
    while @maximumEnergies.length < @_trackLength \
        and @_previousAverageEnergyCoefficient > MINIMUM_THRESHOLD
      @_previousAverageEnergyCoefficient -= 0.1
      @_findBeats(pcmAudioData)

    @_calculateTempo()

    @beats = @maximumEnergies.slice(0)
    @_removeOutOfTimeBeats()
    @_addBeatsInGaps()

  _findBeats: (pcmAudioData) ->
    previousEnergies = []
    @distanceInEnergyIndexBetweenBeats = []
    @maximumEnergies = []
    lastBeatIndex = 0
    @energies = []
    @averageEnergies = []
    @maxEnergy = 0
    @_maxCountIndex = 0
    @_maxBeatIndex = 0
    @_maxBeatValue = 0

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

        # Calculate the threshold the current instant energy must be above
        # to be a potential candidate for a beat.
        threshold = @_previousAverageEnergyCoefficient * previousEnergiesAverage

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
          minDistance = @_beatMinDistanceSamples
          if distanceBetweenBeatIndexes > minDistance
            lastBeatIndex = currentIndex
            @maximumEnergies.push currentTimeSeconds
            @distanceInEnergyIndexBetweenBeats.push
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


  _calculateTempo: ->
    maxDistanceBetwenBeats = @_numberOfPreviousEnergies \
      * MAX_DISTANCE_MULTIPLIER

    # These are buckets which we will use to count where the most beats landed
    @beatDistanceCounts = []

    for i in [0..maxDistanceBetwenBeats]
      @beatDistanceCounts.push
        count: 0
        beats: []

    # Fill the buckets, by counting the occurances of each distance betwee
    # the beats
    for data in @distanceInEnergyIndexBetweenBeats
      distance = data.distance
      distanceBpm = @distanceToBpm(distance)
      if distance < maxDistanceBetwenBeats
        if distanceBpm > @_maxBpm
          distance *= 2
        else if distanceBpm < 80
          distance = Math.floor(distance / 2)
        @beatDistanceCounts[distance].count++
        @beatDistanceCounts[distance].beats.push data

    @_maxCountIndex = 0

    # Now we have them grouped in classes, we need to estimate the mode value
    # using linear interpolation.
    # More information and the formula are described here:
    # http://mathforum.org/library/drmath/view/72977.html
    #
    # We assume that the bpm of the class is in the middle.

    # Find the index of the distance that occurs the most
    maxCountSoFar = 0
    for beatDistanceCount, i in @beatDistanceCounts
      if beatDistanceCount.count > maxCountSoFar
        maxCountSoFar = beatDistanceCount.count
        @_maxCountIndex = i
        @_principalBeat = beatDistanceCount

    middleOfModalClass = @distanceToBpm(@_maxCountIndex)
    middleOfClassAboveModalClass = @distanceToBpm(@_maxCountIndex - 1)
    middleOfClassBelowModalClass = @distanceToBpm(@_maxCountIndex + 1)
    upperBoundOfModalClass = middleOfClassAboveModalClass - \
      (middleOfClassAboveModalClass - middleOfModalClass) / 2
    lowerBoundOfModalClass = middleOfClassBelowModalClass + \
      (middleOfModalClass - middleOfClassBelowModalClass) / 2

    widthOfModalClass = upperBoundOfModalClass - lowerBoundOfModalClass

    classBelowModalClass = @beatDistanceCounts[@_maxCountIndex + 1]
    if classBelowModalClass?
      frequencyOfClassBellowModalClass = classBelowModalClass.count
    else
      frequencyOfClassBellowModalClass = 0

    classAboveModalClass = @beatDistanceCounts[@_maxCountIndex - 1]
    if classAboveModalClass?
      frequencyOfClassAboveModalClass = classAboveModalClass.count
    else
      frequencyOfClassAboveModalClass = 0
    d1 = maxCountSoFar - frequencyOfClassBellowModalClass
    d2 = maxCountSoFar - frequencyOfClassAboveModalClass
    mode = lowerBoundOfModalClass + (d1 / (d1 + d2)) * widthOfModalClass

    @_meanCount = @bpmToDistance(mode)

    @bpm = mode

  _removeOutOfTimeBeats: ->
    # Find the most energetic of the principal beats
    maximumEnergyIndex = 0
    maxMaximumEnergy = 0
    if @_principalBeat?
      for beat in @_principalBeat.beats
        if beat.energy > maxMaximumEnergy
          maximumEnergiesIndex = beat.maximumEnergiesIndex
          maxMaximumEnergy = beat.energy

    @principalBeatTime = @beats[maximumEnergiesIndex]

    @_maxEnergyDistance = @_meanCount

    lowerBound = @_maxEnergyDistance - MAX_SEARCH_WINDOW_SIZE
    upperBound = @_maxEnergyDistance + MAX_SEARCH_WINDOW_SIZE

    indexesToRemove = []
    distanceSoFar = 0

    # Removep to the left
    if maximumEnergyIndex > 0
      for i in [maximumEnergiesIndex..0] by -1
        energy = @distanceInEnergyIndexBetweenBeats[i]
        distance = energy.distance + distanceSoFar
        if distance < lowerBound or distance > upperBound
          distanceSoFar += energy.distance
          if distanceSoFar > upperBound
            distanceSoFar = 0
          indexesToRemove.splice 0, 0, i
        else
          distanceSoFar = 0

    # Remove to the right
    distanceSoFar = 0
    distanceLength = @distanceInEnergyIndexBetweenBeats.length - 1
    for i in [0..distanceLength]
      energy = @distanceInEnergyIndexBetweenBeats[i]
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

  _getSecondsPerInstantEnergy: ->
    @_samplesPerInstantEnergy / SAMPLE_RATE

  distanceToTime: (distance) ->
    secondsPerInstantEnegy = @_getSecondsPerInstantEnergy()
    distance * secondsPerInstantEnegy

  distanceToBpm: (distance) ->
    60 / @distanceToTime(distance)

  bpmToDistance: (bpm) ->
    60 / bpm / @_getSecondsPerInstantEnergy()

  _addBeatsInGaps: ->
    @interpolatedBeats = []
    # Interpolate beats in the gaps between existing ones.
    lowerBound = @distanceToTime(@_maxEnergyDistance - MAX_SEARCH_WINDOW_SIZE)
    upperBound = @distanceToTime(@_maxEnergyDistance + MAX_SEARCH_WINDOW_SIZE)
    meanLength = @distanceToTime(@_maxEnergyDistance)
    beatsToInsert = []
    for i in [0..@beats.length - 2]
      beat = @beats[i]
      nextBeat = @beats[i + 1]
      gap = nextBeat - beat
      continue if gap >= lowerBound and gap <= upperBound
      subdivisions = gap / meanLength
      if subdivisions < 1
        subdivisions = 2
      newBeats = []
      numberOfNewBeats = Math.round(subdivisions)
      for j in [1..numberOfNewBeats]
        newTime = beat + (gap / numberOfNewBeats) * j
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

    # Add beats to the beginning
    nextTime = @beats[0] - meanLength
    while nextTime > 0
      @beats.splice 0, 0, nextTime
      @interpolatedBeats.splice 0, 0, nextTime
      nextTime -= meanLength

    # Add beats to the end
    nextTime = @beats[@beats.length - 1] + meanLength
    while nextTime < @_trackLength
      @beats.push nextTime
      @interpolatedBeats.push nextTime
      nextTime += meanLength







