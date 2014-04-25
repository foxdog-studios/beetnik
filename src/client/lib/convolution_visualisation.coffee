class @BeatDetectorVisualisation
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (beatDetector, start, end) ->
    @cvs.width = @cvs.width

    window = end - start
    pixelsPerSecond = @cvs.width / window
    pixelsPerEnergy = @cvs.height / beatDetector.maxEnergy

    getX = (seconds) ->
      Math.round((seconds - start) * pixelsPerSecond)

    getY = (energy) ->
     Math.round(-energy * pixelsPerEnergy)


    # Maximum energies
    @ctx.fillStyle = '#00FF00'
    for [i, energy] in beatDetector.energies
      continue if i < start
      break if i > end
      @ctx.fillRect(getX(i), @cvs.height, 1, getY(energy))

    # Average energies
    @ctx.fillStyle = 'rgba(255, 0, 255, 1)'
    for [i, energy] in beatDetector.averageEnergies
      @ctx.fillRect(getX(i), @cvs.height, 1, getY(energy))

    # Convolution
    @ctx.fillStyle = 'rgba(0, 255, 255, 1)'
    for [i, conv] in beatDetector.convolution
      continue if i < start
      break if i > end
      @ctx.fillRect(getX(i), @cvs.height, 1,
                    -conv * @cvs.height / 2)

    # Maximum Energies
    @ctx.fillStyle = '#FFFFFF'
    for beat in beatDetector.maximumEnergies
      continue if beat < start
      break if beat > end
      @ctx.fillRect(getX(beat), 0, 1, Math.round(@cvs.height / 12))



