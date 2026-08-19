import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var manifest: null

  property int bpm: 120
  property int beatsPerBar: 4
  property int volume: 65
  property bool active: false
  property int pulse: 0
  property int tapCount: 0
  property string errorText: ""

  property bool configured: false
  property bool restartRequested: false
  property var tapTimes: []

  readonly property string enginePath: String(Qt.resolvedUrl("metronome-engine")).replace(/^file:\/\//, "")

  function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(maximum, Math.round(Number(value))))
  }

  function configure(settings) {
    if (configured) return
    var values = settings || {}
    bpm = clamp(values.bpm === undefined ? 120 : values.bpm, 30, 240)
    beatsPerBar = clamp(values.beatsPerBar === undefined ? 4 : values.beatsPerBar, 1, 12)
    volume = clamp(values.volume === undefined ? 65 : values.volume, 10, 100)
    configured = true
  }

  function engineCommand() {
    return [enginePath, String(bpm), String(beatsPerBar), String(volume)]
  }

  function launchEngine() {
    errorText = ""
    engineProcess.command = engineCommand()
    engineProcess.running = true
    active = true
    pulse += 1
  }

  function start() {
    if (engineProcess.running) return
    restartRequested = false
    launchEngine()
  }

  function stop() {
    restartRequested = false
    active = false
    engineProcess.running = false
  }

  function toggle() {
    if (active) stop()
    else start()
  }

  function restartAtCurrentTempo() {
    if (!active) return
    if (engineProcess.running) {
      restartRequested = true
      engineProcess.running = false
    } else {
      launchEngine()
    }
  }

  function setBpm(value) {
    var next = clamp(value, 30, 240)
    if (next === bpm) return
    bpm = next
    restartAtCurrentTempo()
  }

  function adjustBpm(delta) {
    setBpm(bpm + delta)
  }

  function setBeatsPerBar(value) {
    var next = clamp(value, 1, 12)
    if (next === beatsPerBar) return
    beatsPerBar = next
    restartAtCurrentTempo()
  }

  function registerTap() {
    var now = Date.now()
    var nextTimes = tapTimes.slice(0)

    if (nextTimes.length > 0) {
      var gap = now - nextTimes[nextTimes.length - 1]
      if (gap < 100 || gap > 2000) nextTimes = []
    }

    nextTimes.push(now)
    if (nextTimes.length > 6) nextTimes.shift()
    tapTimes = nextTimes
    tapCount = nextTimes.length
    tapResetTimer.restart()

    if (nextTimes.length < 2) return
    var total = 0
    for (var i = 1; i < nextTimes.length; i++) total += nextTimes[i] - nextTimes[i - 1]
    setBpm(60000 / (total / (nextTimes.length - 1)))
  }

  Timer {
    id: beatTimer
    interval: Math.round(60000 / root.bpm)
    repeat: true
    running: root.active
    onTriggered: root.pulse += 1
  }

  Timer {
    id: tapResetTimer
    interval: 2000
    repeat: false
    onTriggered: {
      root.tapTimes = []
      root.tapCount = 0
    }
  }

  Process {
    id: engineProcess

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.errorText = text.trim()
    }

    onExited: function(exitCode) {
      if (root.restartRequested && root.active) {
        root.restartRequested = false
        Qt.callLater(root.launchEngine)
        return
      }

      if (root.active) {
        root.active = false
        if (exitCode !== 0 && root.errorText === "")
          root.errorText = "The audio engine stopped unexpectedly."
      }
    }
  }

  Component.onDestruction: engineProcess.running = false
}
