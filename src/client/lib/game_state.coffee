class @GameState
  constructor: (@game, @pubsub) ->
    @pubsub.on 'beat', (@onBeat, @beatTime) =>

  preload: ->
    @game.load.image('person', '/person-11.png')
    @game.load.image('player', '/dog.png')
    @game.load.image('ground', '/brick-floor-top.png')

  create: ->
    @game.stage.backgroundColor = 0x4488cc

    # Don't pause the game when the window loses focus
    @game.stage.disableVisibilityChange = true

    # Define movement constants
    @MAX_SPEED = 250 # pixels/second
    @ACCELERATION = 600 # pixels/second/second
    @DRAG = 400 # pixels/second
    @GRAVITY = 980 # pixels/second/second
    @JUMP_SPEED = -200 # pixels/second (negative y is up)

    numberOfCrowdMembers = 10
    @crowdMembers = []
    # Create crowd
    for i in [0..numberOfCrowdMembers]
      crowdMember = @game.add.sprite(
        @game.width/numberOfCrowdMembers * i,
        @game.height - 32,
        'person'
      )
      @game.physics.enable(crowdMember, Phaser.Physics.ARCADE)
      crowdMember.body.maxVelocity.setTo(@MAX_SPEED, @MAX_SPEED * 10)
      crowdMember.body.drag.setTo(@DRAG, 0)

      crowdMember.body.collideWorldBounds = true
      @crowdMembers.push crowdMember

    # Create a player sprite
    @player = @game.add.sprite(@game.width/2, @game.height - 32, 'player')

    # Enable physics on the player
    @game.physics.enable(@player, Phaser.Physics.ARCADE)

    # Make player collide with world boundaries so he doesn't leave the stage
    @player.body.collideWorldBounds = true

    # Set player minimum and maximum movement speed
    @player.body.maxVelocity.setTo(@MAX_SPEED, @MAX_SPEED * 10) # x, y

    # Add drag to the player that slows them down when they are not accelerating
    @player.body.drag.setTo(@DRAG, 0) # x, y

    # Since we're jumping we need gravity
    @game.physics.arcade.gravity.y = @GRAVITY

    # Create some ground for the player to walk on
    @ground = @game.add.group()
    for x in [0..@game.width] by 16
        # Add the ground blocks, enable physics on each, make them immovable
        groundBlock = @game.add.sprite(x, @game.height - 16, 'ground')
        @game.physics.enable(groundBlock, Phaser.Physics.ARCADE)
        groundBlock.body.immovable = true
        groundBlock.body.allowGravity = false
        @ground.add(groundBlock)

    # Capture certain keys to prevent their default actions in the browser.
    # @is only necessary because @is an HTML5 game. Games on other
    # platforms may not need code like @
    @game.input.keyboard.addKeyCapture [
        Phaser.Keyboard.LEFT,
        Phaser.Keyboard.RIGHT,
        Phaser.Keyboard.UP,
        Phaser.Keyboard.DOWN
    ]

    # Just for fun, draw some height markers so we can see how high we're jumping
    #@drawHeightMarkers()

    # Show FPS
    @game.time.advancedTiming = true
    @fpsText = @game.add.text(
        20, 20, '', font: '16px Arial', fill: '#ffffff'
    )

  update: ->
    # The update() method is called every frame
    GameState.prototype.update = ->
      if @game.time.fps != 0
        @fpsText.setText(@game.time.fps + ' FPS')

    # Collide the player with the ground
    @game.physics.arcade.collide(@player, @ground)

    for crowdMember in @crowdMembers
      @game.physics.arcade.collide(crowdMember, @ground)
      @game.physics.arcade.collide(crowdMember, @player)

    if @input.keyboard.isDown(Phaser.Keyboard.LEFT)
      # If the LEFT key is down, set the player velocity to move left
      @player.body.acceleration.x = -@ACCELERATION
    else if @input.keyboard.isDown(Phaser.Keyboard.RIGHT)
      # If the RIGHT key is down, set the player velocity to move right
      @player.body.acceleration.x = @ACCELERATION
    else
      @player.body.acceleration.x = 0

    # Set a iable that is true when the player is touching the ground
    onTheGround = @player.body.touching.down

    if onTheGround and @input.keyboard.justPressed(Phaser.Keyboard.UP)
      # Jump when the player is touching the ground and the up arrow is pressed
      @player.body.velocity.y = @JUMP_SPEED

    for crowdMember in @crowdMembers
      if crowdMember.body.touching.down and @onBeat
        crowdMember.body.velocity.y = @JUMP_SPEED
        continue
        continue unless @beatTime
        originalY = crowdMember.y
        tweenTo = originalY - 20
        time = (@beatTime * 1000 / 2) - 100
        tween = @game.add.tween(crowdMember).to(y: tweenTo,
          time, Phaser.Easing.Linear.None)
        tween.to(y: originalY, time, Phaser.Easing.Linear.None)
        tween.start()

