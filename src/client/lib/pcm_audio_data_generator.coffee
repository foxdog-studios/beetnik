class @PcmAudioGenerator
  getPcmAudioData: (offlineContext, audioSample, callback) ->
    renderAudioSampleOffline = (audioSample) =>
      offlineContext.oncomplete = (event) ->
        # Only doing one channel, so index at zero
        callback event.renderedBuffer.getChannelData(0)
      audioSample.tryPlay()
      offlineContext.startRendering()
    audioSample.loadAudio offlineContext, renderAudioSampleOffline

