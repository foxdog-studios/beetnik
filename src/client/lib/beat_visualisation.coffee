class @BeatVisualisation
  constructor: (selector) ->
    @cvs = $(selector)[0]
    @ctx = @cvs.getContext '2d'
    @cvs.width = $(@cvs).width()

  render: (timeOut) ->
    if @handle?
      Meteor.clearTimeout @handle
    @ctx.fillStyle = '#04f771'
    @ctx.fillRect(0, 0, @cvs.width, @cvs.height)
    @handle = Meteor.setTimeout =>
      @cvs.width = @cvs.width
      @handle = null
    , timeOut

