getAudioContext = ->
  AudioContext = AudioContext or webkitAudioContext
  new AudioContext()

audioContext = null
audioSample = null
timeline = null

beats = null

beatVisualisation = null

playTrack = ->
  beatsClone = beats.slice(0)

  if audioSample.playing
    return audioSample.stop()
  audioSample.tryPlay()
  startTime = audioContext.currentTime

  handle = null

  update = ->
    playbackTime = audioContext.currentTime - startTime
    timeline.render(playbackTime, SAMPLE_LENGTH_SECONDS)
    if playbackTime > SAMPLE_LENGTH_SECONDS
      audioSample.stop()
      Session.set 'playing', audioSample.playing
    if audioSample.playing
      if beatsClone.length > 0 and beatsClone[0] <= playbackTime
        beatVisualisation.render(50)
        beatsClone.splice(0, 1)
      requestAnimationFrame(update)
    else
      timeline.render(0, SAMPLE_LENGTH_SECONDS)
  requestAnimationFrame(update)

updateAudioFromPcmData = (pcmAudioData) ->
  Session.set 'hasPcmAudioData', true
  waveformVisualisation = new WaveformVisualisation('#waveform', pcmAudioData)
  waveformVisualisation.render()

  beats = new SoundEnergyBeatDetector().detectBeats(pcmAudioData)

  beatsVisualisation = new BeatsVisualisation('#beats')
  beatsVisualisation.render(beats, SAMPLE_LENGTH_SECONDS)

  beatVisualisation = new BeatVisualisation('#beat')

updateAudioFromArrayBuffer = (arrayBuffer) ->
  Session.set 'hasPcmAudioData', false
  Session.set 'hasAudio', false

  audioContext = getAudioContext()
  audioSample = new ArrayBufferAudioSample(arrayBuffer)
  audioSample.loadAudio audioContext, ->
    Session.set 'hasAudio', true

  pcmAudioSample = new ArrayBufferAudioSample(arrayBuffer)
  pcmAudioGenerator = new PcmAudioGenerator()
  pcmAudioGenerator.getPcmAudioData(pcmAudioSample, updateAudioFromPcmData)


Template.waveform.rendered = ->
  timeline = new Timeline('#timeline')
  loadAudioFromUrl '/sample.mp3', updateAudioFromArrayBuffer

Template.waveform.helpers
  hasPcmAudioData: ->
    Session.get 'hasPcmAudioData'

  disabled: ->
    unless Session.get('hasAudio') and Session.get('hasPcmAudioData')
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

  'change #file': (event) ->
    file = event.target.files[0]

    return unless file.type.match('audio.*')

    reader = new FileReader()

    reader.onload = (fileEvent) ->
      updateAudioFromArrayBuffer(fileEvent.target.result)

    reader.readAsArrayBuffer file

