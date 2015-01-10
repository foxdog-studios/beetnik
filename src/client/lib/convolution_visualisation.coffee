class @BeatDetectorVisualisation
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (beatDetector, start, end) ->
    @cvs.width = @cvs.width

    beatsHeight = @cvs.height / 12
    energiesHeight = @cvs.height - beatsHeight

    window = end - start
    pixelsPerSecond = @cvs.width / window
    pixelsPerEnergy = energiesHeight / 2 / beatDetector.maxEnergy

    getX = (seconds) ->
      Math.round((seconds - start) * pixelsPerSecond)

    getY = (energy) ->
     Math.round(-energy * pixelsPerEnergy)


    # Maximum energies
    @ctx.fillStyle = '#00bc34'
    for [i, energy] in beatDetector.energies
      continue if i < start
      break if i > end
      @ctx.fillRect(getX(i), energiesHeight, 1, getY(energy))

    # Average energies
    @ctx.fillStyle = 'rgba(255, 0, 255, 0.5)'
    for [i, energy] in beatDetector.averageEnergies
      @ctx.fillRect(getX(i), energiesHeight, 1, getY(energy))



    # Beats

    beatHeight = beatsHeight / 2
    @ctx.fillStyle = '#ff9045'
    for beat in beatDetector.beats
      continue if beat < start
      break if beat > end
      @ctx.fillRect(
        getX(beat),
        @cvs.height - beatHeight * 2,
        1,
        beatHeight
      )

    # Interpolated beats
    @ctx.fillStyle = '#0088ff'
    for beat in beatDetector.interpolatedBeats
      continue if beat < start
      break if beat > end
      height = Math.round(@cvs.height / 12)
      @ctx.fillRect(
        getX(beat),
        @cvs.height - beatHeight * 2,
        1,
        beatHeight
      )

    @ctx.fillStyle = '#ff0000'
    @ctx.fillRect(
      getX(beatDetector.principalBeatTime),
      @cvs.height - beatHeight * 2,
      1,
      beatHeight
    )

    # Maximum Energies
    @ctx.fillStyle = '#222'
    for beat in beatDetector.maximumEnergies
      continue if beat < start
      break if beat > end
      @ctx.fillRect(getX(beat), @cvs.height - beatHeight, 1, beatHeight)

