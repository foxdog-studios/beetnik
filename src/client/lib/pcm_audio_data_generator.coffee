class @PcmAudioGenerator
  getPcmAudioData: (offlineContext, audioSample, callback) ->
    filter = offlineContext.createBiquadFilter()
    filter.type = "lowpass"
    console.log filter.frequency.value
    renderAudioSampleOffline = (audioSample) =>
      offlineContext.oncomplete = (event) ->
        # Only doing one channel, so index at zero
        callback event.renderedBuffer.getChannelData(0)
      audioSample.connect(offlineContext.destination)
      audioSample.tryPlay()
      offlineContext.startRendering()
    audioSample.loadAudio offlineContext, renderAudioSampleOffline

