import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "dlpwaters.metronome"

  readonly property var metronomeService: bar && bar.shell
    ? bar.shell.serviceFor(moduleName)
    : null
  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false

  function syncService() {
    if (metronomeService && typeof metronomeService.configure === "function")
      metronomeService.configure(settings)
    injectPanel()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("metronomeService" in target) target.metronomeService = root.metronomeService
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function togglePanel() { if (panelLoader.item) panelLoader.item.toggle() }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: syncService()
  onSettingsChanged: syncService()
  onMetronomeServiceChanged: syncService()
  Component.onCompleted: syncService()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      root.syncService()
    }
  }

  IpcHandler {
    target: "dlpwaters.metronome"
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
    function play(): void { if (root.metronomeService) root.metronomeService.start() }
    function stop(): void { if (root.metronomeService) root.metronomeService.stop() }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰎈"
    active: !!root.metronomeService && root.metronomeService.active
    activeColor: Color.accent
    tooltipText: root.metronomeService
      ? "Metronome · " + root.metronomeService.bpm + " BPM"
        + (root.metronomeService.active ? " · Playing" : "")
      : "Metronome"
    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton && root.metronomeService)
        root.metronomeService.toggle()
      else if (mouseButton === Qt.LeftButton)
        root.togglePanel()
    }
    onWheelMoved: function(delta) {
      if (root.metronomeService)
        root.metronomeService.adjustBpm(delta > 0 ? 1 : -1)
    }
  }
}
