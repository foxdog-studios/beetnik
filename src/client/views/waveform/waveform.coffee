THRESHOLD_CONSTANT = 1.3
SAMPLES_PER_INSTANT_ENERGY = 1024
NUMBER_OF_PREVIOUS_SAMPLES = 43

getAudioContext = ->
  AudioContext = AudioContext or webkitAudioContext
  new AudioContext()

audioContext = null
audioSample = null
timeline = null

beats = null
pcmAudioData = null

beatVisualisation = null
beatsVisualisation = null

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

updateBeats = ->
  pAEC = Session.get 'previousAverageEnergyCoefficient'
  unless pAEC?
    pAEC = THRESHOLD_CONSTANT
    Session.set 'previousAverageEnergyCoefficient', pAEC

  sPIE = Session.get 'samplesPerInstantEnergy'
  unless sPIE
    sPIE = SAMPLES_PER_INSTANT_ENERGY
    Session.set 'samplesPerInstantEnergy', sPIE

  nOPS = Session.get 'numberOfPreviousSamples'
  unless nOPS
    nOPS = NUMBER_OF_PREVIOUS_SAMPLES
    Session.set 'numberOfPreviousSamples', nOPS

  soundEnergyBeatDetector = new SoundEnergyBeatDetector()
  beats = soundEnergyBeatDetector.detectBeats(pcmAudioData, pAEC, sPIE, nOPS)
  beatsVisualisation.render(beats, SAMPLE_LENGTH_SECONDS)

updateAudioFromPcmData = (_pcmAudioData) ->
  pcmAudioData = _pcmAudioData
  Session.set 'hasPcmAudioData', true
  waveformVisualisation = new WaveformVisualisation('#waveform', pcmAudioData)
  waveformVisualisation.render()
  updateBeats()

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
  beatsVisualisation = new BeatsVisualisation('#beats')
  beatVisualisation = new BeatVisualisation('#beat')
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

  previousAverageEnergyCoefficient: ->
    Session.get 'previousAverageEnergyCoefficient'

  samplesPerInstantEnergy: ->
    Session.get 'samplesPerInstantEnergy'

  numberOfPreviousSamples: ->
    Session.get 'numberOfPreviousSamples'

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
      if audioSample?
        audioSample.stop()
        Session.set 'playing', audioSample.playing
      updateAudioFromArrayBuffer(fileEvent.target.result)

    reader.readAsArrayBuffer file

  'change [name="previous-average-energy-coefficient"]': (event) ->
    value = $(event.target).val()
    Session.set 'previousAverageEnergyCoefficient', value
    updateBeats()

  'change [name="samples-per-instant-energy"]': (event) ->
    value = $(event.target).val()
    Session.set 'samplesPerInstantEnergy', value
    updateBeats()

  'change [name="number-of-previous-samples"]': (event) ->
    value = $(event.target).val()
    Session.set 'numberOfPreviousSamples', value
    updateBeats()

