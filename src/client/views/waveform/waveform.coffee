THRESHOLD_CONSTANT = 6
VARIANCE_COEFFICIENT = 0
SAMPLES_PER_INSTANT_ENERGY = 300
NUMBER_OF_PREVIOUS_SAMPLES = 42
MAX_BPM = 253

CHANNELS = 1
SAMPLE_RATE = 44100

audioContext = null

getAudioContext = ->
  AudioContext = window.AudioContext or window.webkitAudioContext
  unless audioContext?
    audioContext = new AudioContext()
  audioContext

getOfflineAudioContext = (channels, length, sampleRate) ->
  OfflineAudioContext = \
      window.OfflineAudioContext or window.webkitOfflineAudioContext
  new OfflineAudioContext(channels, length, sampleRate)

audioSample = null
timeline = null

beatDetector = null
beats = null
pcmAudioData = null

metronomeAudioSample = null

beatVisualisation = null
beatDetectorVisualisation = null
histogramVisutalisation = null

sampleLengthSeconds = 0
trackStartTime = 0

windowStart = 0
windowEnd = null

playTrack = ->
  beatsClone = beatDetector.beats.slice(0)

  metronomeClickHasBeenScheduled = false

  while beatsClone.length and beatsClone[0] < trackStartTime
    beatsClone.splice(0, 1)

  if audioSample.playing
    return audioSample.stop()
  gain = if Session.get 'click'
    0.3
  else
    1
  audioSample.tryPlay(trackStartTime, gain)
  startTime = audioContext.currentTime

  handle = null

  update = ->
    playbackTime = audioContext.currentTime - startTime + trackStartTime
    if playbackTime > sampleLengthSeconds
      audioSample.stop()
      Session.set 'playing', audioSample.playing
      timeline.render(trackStartTime, windowStart, windowEnd)
    if audioSample.playing
      timeline.render(playbackTime, windowStart, windowEnd)
      # Schedule metronome clicks so we they happen accurately
      # see:
      # http://www.html5rocks.com/en/tutorials/audio/scheduling/
      if not metronomeClickHasBeenScheduled and \
          metronomeAudioSample? and Session.get('click') \
          and beatsClone.length > 0
        nextBeatScheduleTime = audioContext.currentTime - playbackTime + beatsClone[0]
        metronomeAudioSample.tryPlay(undefined, undefined, nextBeatScheduleTime)
        metronomeClickHasBeenScheduled = true
      if beatsClone.length > 0 and beatsClone[0] <= playbackTime
        #Beat!
        if beatsClone.length > 2
          beatTime = beatsClone[1] - beatsClone[0]
        gamePubSub.trigger 'beat', true, beatTime
        beatVisualisation.render(50)
        beatsClone.splice(0, 1)
        metronomeClickHasBeenScheduled = false
      else
        gamePubSub.trigger 'beat', false
      requestAnimationFrame(update)
  requestAnimationFrame(update)

updateSongPlace = (fractionThroughSong) ->
  if audioSample.playing
    audioSample.stop()
    Session.set 'playing', audioSample.playing
  trackStartTime = windowStart + ((windowEnd - windowStart) * fractionThroughSong)
  timeline.render(trackStartTime, windowStart, windowEnd)

updateBeats = ->
  pAEC = parseFloat Session.get 'previousAverageEnergyCoefficient'
  unless $.isNumeric pAEC
    pAEC = THRESHOLD_CONSTANT
    Session.set 'previousAverageEnergyCoefficient', pAEC

  pEVC = parseFloat Session.get 'previousEnergyVarianceCoefficient'
  unless $.isNumeric pEVC
    pEVC = VARIANCE_COEFFICIENT
    Session.set 'previousEnergyVarianceCoefficient', pEVC

  sPIE = parseFloat Session.get 'samplesPerInstantEnergy'
  unless $.isNumeric sPIE
    sPIE = SAMPLES_PER_INSTANT_ENERGY
    Session.set 'samplesPerInstantEnergy', sPIE

  nOPS = parseFloat Session.get 'numberOfPreviousSamples'
  unless $.isNumeric nOPS
    nOPS = NUMBER_OF_PREVIOUS_SAMPLES
    Session.set 'numberOfPreviousSamples', nOPS

  maxBpm = parseFloat Session.get 'maxBpm'
  unless $.isNumeric maxBpm
    maxBpm = MAX_BPM
    Session.set 'maxBpm', maxBpm

  beatDetector = new SoundEnergyBeatDetector()
  beatDetector.detectBeats(pcmAudioData, pEVC, pAEC, sPIE, nOPS, maxBpm)
  unless windowEnd?
    windowEnd = sampleLengthSeconds
  Session.set 'bpm', beatDetector.bpm
  updateVisualisation()

updateVisualisation = ->
  beatDetectorVisualisation.render(beatDetector, windowStart,
                                  windowEnd)
  timeline.render(trackStartTime, windowStart, windowEnd)
  histogramVisutalisation.render(beatDetector)

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
  beatVisualisation = new BeatVisualisation('#beat')
  beatDetectorVisualisation = new BeatDetectorVisualisation('#convolution')
  histogramVisutalisation = new BeatDistanceCountHistogram('#histogram')
  loadAudioFromUrl '/millionaire.ogg', updateAudioFromArrayBuffer
  loadAudioFromUrl '/metronome.ogg', (arrayBuffer) ->
    audioContext = getAudioContext()
    metronomeAudioSample = new ArrayBufferAudioSample(arrayBuffer)
    metronomeAudioSample.loadAudio audioContext

  $(window).keydown (event) ->
    # Try playing on spacebar of enter
    if event.keyCode == 32 or event.keyCode == 13
      event.preventDefault()
      tryPlay()

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

  maxBpm: ->
    Session.get 'maxBpm'

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

  clickChecked: ->
    'checked' if Session.get 'click'

  zoom: ->
    zoom = Session.get 'zoom'
    unless zoom?
      zoom = 1
    zoom

  advancedInterface: ->
    Session.get 'advancedInterface'

  advancedInterfaceChecked: ->
    'checked' if Session.get 'advancedInterface'

tryPlay = ->
  return unless audioSample?
  playTrack()
  Session.set 'playing', audioSample.playing

Template.waveform.events
  'click [name="play"]': (event) ->
    event.preventDefault()
    tryPlay()



  'change #file': (event) ->
    event.preventDefault()
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
    event.preventDefault()
    value = parseFloat $(event.target).val()
    Session.set 'previousAverageEnergyCoefficient', value
    updateBeats()

  'change #max-bpm': (event) ->
    event.preventDefault()
    value = parseFloat $(event.target).val()
    Session.set 'maxBpm', value
    updateBeats()

  'change [name="previous-energy-variance-coefficient"]': (event) ->
    event.preventDefault()
    value = parseFloat $(event.target).val()
    Session.set 'previousEnergyVarianceCoefficient', value
    updateBeats()

  'change [name="samples-per-instant-energy"]': (event) ->
    event.preventDefault()
    value = parseFloat $(event.target).val()
    Session.set 'samplesPerInstantEnergy', value
    updateBeats()

  'change [name="number-of-previous-samples"]': (event) ->
    event.preventDefault()
    value = parseFloat $(event.target).val()
    Session.set 'numberOfPreviousSamples', value
    updateBeats()

  'click #timeline': (event) ->
    event.preventDefault()
    $el = $(event.target)
    parentOffset = $el.parent().offset()
    relX = event.pageX - parentOffset.left
    updateSongPlace(relX / $el.width())

  'change [name="click"]': (event) ->
    event.preventDefault()
    value = $(event.target).prop('checked')
    Session.set 'click', value

  'change [name="advanced"]': (event) ->
    event.preventDefault()
    Session.set 'advancedInterface', $(event.target).prop('checked')

  'change [name="zoom"]': (event) ->
    event.preventDefault()
    value = $(event.target).val()
    Session.set 'zoom', value
    window = (sampleLengthSeconds / value) / 2
    windowStart = trackStartTime - window
    if windowStart < 0
      addition = -windowStart
      windowStart = 0
    else
      addition = 0
    windowEnd = trackStartTime + window + addition
    if windowEnd > sampleLengthSeconds
      addition = windowEnd - sampleLengthSeconds
      windowEnd = sampleLengthSeconds
      windowStart -= addition
    updateVisualisation()

