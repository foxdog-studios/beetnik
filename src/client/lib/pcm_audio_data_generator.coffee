getOfflineAudioContext = (channels, length, sampleRate) ->
  OfflineAudioContext = OfflineAudioContext or webkitOfflineAudioContext
  new OfflineAudioContext(channels, length, sampleRate)

@SAMPLE_LENGTH_SECONDS = 20

class @PcmAudioGenerator
  CHANNELS = 1
  SAMPLE_RATE = 44100
  LENGTH = SAMPLE_RATE * SAMPLE_LENGTH_SECONDS

  constructor: ->
    @context = getOfflineAudioContext(CHANNELS, LENGTH, SAMPLE_RATE)

  getPcmAudioData: (audioSample, callback) ->
    renderAudioSampleOffline = (audioSample) =>
      @context.oncomplete = (event) ->
        # Only doing one channel, so index at zero
        callback event.renderedBuffer.getChannelData(0)
      audioSample.tryPlay()
      @context.startRendering()
    audioSample.loadAudio @context, renderAudioSampleOffline

