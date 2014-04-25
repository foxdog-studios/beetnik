class @AverageEnergiesVisulisation
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (averageEnergies, sPIE, sampleLengthSeconds) ->
    @cvs.width = @cvs.width
    @ctx.fillStyle = 'rgba(255, 0, 255, 1)'
    xInterval = @cvs.width / sampleLengthSeconds
    yInterval = @cvs.height / sPIE
    for [i, energy] in averageEnergies
      @ctx.fillRect(Math.round(i * xInterval), @cvs.height, 1,
                    Math.round(-energy * yInterval))

