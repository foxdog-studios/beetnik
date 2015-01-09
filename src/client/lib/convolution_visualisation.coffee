class @BeatDetectorVisualisation
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (beatDetector, start, end) ->
    @cvs.width = @cvs.width

    window = end - start
    pixelsPerSecond = @cvs.width / window
    pixelsPerEnergy = @cvs.height / 2 / beatDetector.maxEnergy

    getX = (seconds) ->
      Math.round((seconds - start) * pixelsPerSecond)

    getY = (energy) ->
     Math.round(-energy * pixelsPerEnergy)


    # Maximum energies
    @ctx.fillStyle = '#00bc34'
    for [i, energy] in beatDetector.energies
      continue if i < start
      break if i > end
      @ctx.fillRect(getX(i), @cvs.height, 1, getY(energy))

    # Average energies
    @ctx.fillStyle = 'rgba(255, 0, 255, 0.5)'
    for [i, energy] in beatDetector.averageEnergies
      @ctx.fillRect(getX(i), @cvs.height, 1, getY(energy))



    # Beats
    @ctx.fillStyle = '#ff9045'
    for beat in beatDetector.beats
      continue if beat < start
      break if beat > end
      height = Math.round(@cvs.height / 12)
      @ctx.fillRect(getX(beat), @cvs.height - height - 3, 1, height + 3)

    # Interpolated beats
    @ctx.fillStyle = '#00ffff'
    for beat in beatDetector.interpolatedBeats
      continue if beat < start
      break if beat > end
      height = Math.round(@cvs.height / 12)
      @ctx.fillRect(getX(beat), @cvs.height - height - 3, 1, height + 3)

    @ctx.fillStyle = '#ff0000'
    height = Math.round(@cvs.height / 12) * 2
    @ctx.fillRect(
      getX(beatDetector.principalBeatTime),
      @cvs.height - height,
      1,
      height
    )

    # Maximum Energies
    @ctx.fillStyle = '#222'
    for beat in beatDetector.maximumEnergies
      continue if beat < start
      break if beat > end
      height = Math.round(@cvs.height / 12)
      @ctx.fillRect(getX(beat), @cvs.height - height, 1, height)

