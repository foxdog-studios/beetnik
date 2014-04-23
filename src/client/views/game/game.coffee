Template.game.rendered = ->
  game = new Phaser.Game(320, 240, Phaser.AUTO, 'game')
  game.state.add('game', new GameState(game, gamePubSub), true)

