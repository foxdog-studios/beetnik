getAudioContext = ->
  AudioContext = AudioContext or webkitAudioContext
  new AudioContext()

audioContext = null
audioSample = null
timeline = null

playTrack = ->

  if audioSample.playing
    return audioSample.stop()
  audioSample.tryPlay()
  startTime = audioContext.currentTime

  update = ->
    playbackTime = audioContext.currentTime - startTime
    timeline.render(playbackTime, SAMPLE_LENGTH_SECONDS)
    if playbackTime > SAMPLE_LENGTH_SECONDS
      audioSample.stop()
      Session.set 'playing', audioSample.playing
    if audioSample.playing
      requestAnimationFrame(update)
    else
      timeline.render(0, SAMPLE_LENGTH_SECONDS)
  requestAnimationFrame(update)

Template.waveform.rendered = ->
  Session.set 'hasPcmAudioData', false
  Session.set 'hasAudio', false
  timeline = new Timeline('#timeline')
  new PcmAudioGenerator('sample.mp3').getPcmAudioData (pcmAudioData) ->
    Session.set 'hasPcmAudioData', true
    waveformVisualisation = new WaveformVisualisation('#waveform', pcmAudioData)
    waveformVisualisation.render()

    audioContext = getAudioContext()
    audioSample = new AudioSample audioContext, 'sample.mp3', (audioSample) ->
      Session.set 'hasAudio', true

Template.waveform.helpers
  hasPcmAudioData: ->
    Session.get 'hasPcmAudioData'

  disabled: ->
    unless Session.get 'hasAudio'
      'disabled'

  playButtonText: ->
    if Session.get 'playing'
      'stop'
    else
      'play'

Template.waveform.events
  'click [name="play"]': (event) ->
    return unless audioSample?
    playTrack()
    Session.set 'playing', audioSample.playing

