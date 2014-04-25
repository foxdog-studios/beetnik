class @ConvolutionVisualisation
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (convolution, sampleLengthSeconds) ->
    @cvs.width = @cvs.width
    @ctx.fillStyle = 'rgba(0, 255, 255, 1)'
    xInterval = @cvs.width / sampleLengthSeconds
    for [i, conv] in convolution
      @ctx.fillRect(Math.round(i * xInterval), @cvs.height, 1,
                    -conv * @cvs.height / 2)

