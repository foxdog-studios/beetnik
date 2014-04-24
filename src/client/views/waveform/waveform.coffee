THRESHOLD_CONSTANT = 1.5
VARIANCE_COEFFICIENT = 0
SAMPLES_PER_INSTANT_ENERGY = 1024
NUMBER_OF_PREVIOUS_SAMPLES = 43

CHANNELS = 1
SAMPLE_RATE = 44100

getAudioContext = ->
  AudioContext = AudioContext or webkitAudioContext
  new AudioContext()

getOfflineAudioContext = (channels, length, sampleRate) ->
  OfflineAudioContext = OfflineAudioContext or webkitOfflineAudioContext
  new OfflineAudioContext(channels, length, sampleRate)

audioContext = null
audioSample = null
timeline = null

beats = null
maximumEnergies = null
pcmAudioData = null

beatVisualisation = null
beatsVisualisation = null
energiesVisualisation = null
averageEnergiesVisualisation = null
convolutionVisualisation = null

sampleLengthSeconds = 0
trackStartTime = 0

playTrack = ->
  beatsClone = beats.slice(0)

  while beatsClone.length and beatsClone[0] < trackStartTime
    beatsClone.splice(0, 1)

  if audioSample.playing
    return audioSample.stop()
  audioSample.tryPlay(trackStartTime)
  startTime = audioContext.currentTime

  handle = null

  update = ->
    playbackTime = audioContext.currentTime - startTime + trackStartTime
    timeline.render(playbackTime, sampleLengthSeconds)
    if playbackTime > sampleLengthSeconds
      audioSample.stop()
      Session.set 'playing', audioSample.playing
    if audioSample.playing
      if beatsClone.length > 0 and beatsClone[0] <= playbackTime
        #Beat!
        if beatsClone.length > 2
          beatTime = beatsClone[1] - beatsClone[0]
        gamePubSub.trigger 'beat', true, beatTime
        beatVisualisation.render(50)
        beatsClone.splice(0, 1)
      else
        gamePubSub.trigger 'beat', false
      requestAnimationFrame(update)
    else
      timeline.render(0, sampleLengthSeconds)
  requestAnimationFrame(update)

updateSongPlace = (fractionThroughSong) ->
  trackStartTime = sampleLengthSeconds * fractionThroughSong
  timeline.render(trackStartTime, sampleLengthSeconds)
  if audioSample.playing
    return audioSample.stop()
  Session.set 'playing', audioSample.playing

updateBeats = ->
  pAEC = Session.get 'previousAverageEnergyCoefficient'
  unless pAEC?
    pAEC = THRESHOLD_CONSTANT
    Session.set 'previousAverageEnergyCoefficient', pAEC

  pEVC = Session.get 'previousEnergyVarianceCoefficient'
  unless pEVC?
    pEVC = VARIANCE_COEFFICIENT
    Session.set 'previousEnergyVarianceCoefficient', pEVC

  sPIE = Session.get 'samplesPerInstantEnergy'
  unless sPIE
    sPIE = SAMPLES_PER_INSTANT_ENERGY
    Session.set 'samplesPerInstantEnergy', sPIE

  nOPS = Session.get 'numberOfPreviousSamples'
  unless nOPS
    nOPS = NUMBER_OF_PREVIOUS_SAMPLES
    Session.set 'numberOfPreviousSamples', nOPS

  soundEnergyBeatDetector = new SoundEnergyBeatDetector()
  [maximumEnergies, energies, averageEnergies, maxEnergy, bpm, convolution,
   beats] = \
    soundEnergyBeatDetector.detectBeats(pcmAudioData, pEVC, pAEC, sPIE,
                                              nOPS)
  Session.set 'bpm', bpm
  beatsVisualisation.render(maximumEnergies, sampleLengthSeconds)
  energiesVisualisation.render(energies, maxEnergy, sampleLengthSeconds)
  averageEnergiesVisualisation.render(averageEnergies, maxEnergy,
                                      sampleLengthSeconds)
  convolutionVisualisation.render(convolution, sampleLengthSeconds)

updateAudioFromPcmData = (_pcmAudioData) ->
  pcmAudioData = _pcmAudioData
  Session.set 'hasPcmAudioData', true
  waveformVisualisation = new WaveformVisualisation('#waveform', pcmAudioData)
  waveformVisualisation.render()
  updateBeats()

updateAudioFromArrayBuffer = (arrayBuffer) ->
  Session.set 'hasPcmAudioData', false
  Session.set 'hasAudio', false

  unless audioContext?
    audioContext = getAudioContext()
  audioSample = new ArrayBufferAudioSample(arrayBuffer)

  # XXX: To know the correct length we need to make the offline audio context,
  # we need to decode the audio, using an AudioContext (which we also use for
  # playback).
  audioSample.loadAudio audioContext, (audioSample) ->
    Session.set 'hasAudio', true

    pcmAudioSample = new ArrayBufferAudioSample(arrayBuffer)
    length = audioSample.buffer.length
    sampleLengthSeconds = length / SAMPLE_RATE
    offlineAudioContext = \
        getOfflineAudioContext(CHANNELS, length, SAMPLE_RATE)
    pcmAudioGenerator = new PcmAudioGenerator()
    pcmAudioGenerator.getPcmAudioData(offlineAudioContext,
                                      pcmAudioSample, updateAudioFromPcmData)

Template.waveform.rendered = ->
  timeline = new Timeline('#timeline')
  beatsVisualisation = new BeatsVisualisation('#beats')
  energiesVisualisation = new EnergiesVisualisation('#energies')
  averageEnergiesVisualisation = \
      new AverageEnergiesVisulisation('#average-energies')
  beatVisualisation = new BeatVisualisation('#beat')
  convolutionVisualisation = new ConvolutionVisualisation('#convolution')
  loadAudioFromUrl '/selfie-short.mp3', updateAudioFromArrayBuffer

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

  previousEnergyVarianceCoefficient: ->
    Session.get 'previousEnergyVarianceCoefficient'

  samplesPerInstantEnergy: ->
    Session.get 'samplesPerInstantEnergy'

  numberOfPreviousSamples: ->
    Session.get 'numberOfPreviousSamples'

  bpm: ->
    bpm = Session.get 'bpm'
    return '?' unless bpm?
    bpm.toFixed(2)

Template.waveform.events
  'click [name="play"]': (event) ->
    return unless audioSample?
    playTrack()
    Session.set 'playing', audioSample.playing

  'change #file': (event) ->
    file = event.target.files[0]

    return unless file?.type.match('audio.*')

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


  'change [name="previous-energy-variance-coefficient"]': (event) ->
    value = $(event.target).val()
    Session.set 'previousEnergyVarianceCoefficient', value
    updateBeats()

  'change [name="samples-per-instant-energy"]': (event) ->
    value = $(event.target).val()
    Session.set 'samplesPerInstantEnergy', value
    updateBeats()

  'change [name="number-of-previous-samples"]': (event) ->
    value = $(event.target).val()
    Session.set 'numberOfPreviousSamples', value
    updateBeats()

  'click #timeline': (event) ->
    $el = $(event.target)
    parentOffset = $el.parent().offset()
    relX = event.pageX - parentOffset.left
    updateSongPlace(relX / $el.width())

