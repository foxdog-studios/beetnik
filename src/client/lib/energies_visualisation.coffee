class @EnergiesVisualisation
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (energies, sPIE, sampleLengthSeconds) ->
    @cvs.width = @cvs.width
    @ctx.fillStyle = '#00FF00'
    xInterval = @cvs.width / sampleLengthSeconds
    yInterval = @cvs.height / sPIE
    for [i, energy] in energies
      @ctx.fillRect(Math.round(i * xInterval), @cvs.height, 1,
                    Math.round(-energy * yInterval))

