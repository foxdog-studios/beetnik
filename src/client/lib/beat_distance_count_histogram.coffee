class @BeatDistanceCountHistogram
  constructor: (selector) ->
    @_$ = $(selector)
    @_cvs = @_$[0]
    @_ctx = @_cvs.getContext '2d'
    @_cvs.width = @_$.width()
    @_cvs.height = @_$.height()
    @_histogramHeight = 24


  render: (beatDetector, start, end) ->
    @_cvs.width = @_cvs.width

    histrogramCounts = []


    maxCountSoFar = 0
    maxCountSoFarIndex = 0

    for beatDistanceCount, index in beatDetector.beatDistanceCounts
      count = beatDistanceCount.beats.length
      if count > maxCountSoFar
        maxCountSoFar = count
        maxCountSoFarIndex = index
      histrogramCounts.push
        index: index
        count: count

    textMaxWidth = @_histogramHeight * 5
    pixelsPerCount = (@_cvs.width - textMaxWidth) / maxCountSoFar

    @_cvs.height = histrogramCounts.length * @_histogramHeight
    @_$.height(@_cvs.height)

    for histogramCount, i in histrogramCounts
      yPosition = @_histogramHeight * i
      barHeight = @_histogramHeight - 2
      if histogramCount.index == maxCountSoFarIndex
        @_ctx.fillStyle = '#2a2'
      else
        @_ctx.fillStyle = '#222'
      barWidth = Math.round(histogramCount.count * pixelsPerCount)
      @_ctx.fillRect(
        textMaxWidth,
        yPosition,
        barWidth,
        barHeight
      )
      fontSize = barHeight - 8
      @_ctx.fillStyle = '#555'
      @_ctx.font = "#{fontSize}px Arial"
      distance = histogramCount.index
      bpm = beatDetector.distanceToBpm(distance).toFixed(2)
      @_ctx.textAlign = 'right'
      @_ctx.fillText(
        "#{bpm}bpm / #{distance}",
        textMaxWidth - 5,
        yPosition + barHeight / 2 + fontSize / 2,
        textMaxWidth
      )
      @_ctx.fillStyle = '#fff'
      @_ctx.textAlign = 'center'
      @_ctx.fillText(
        histogramCount.count,
        textMaxWidth + (fontSize + 5) / 2,
        yPosition + barHeight / 2 + fontSize / 2,
        barWidth - 5
      )

