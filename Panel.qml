import QtQuick
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "dlpwaters.metronome"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var metronomeService: null
  readonly property var barIdentity: hostWidget || root

  readonly property color foreground: Color.popups.text
  readonly property color mutedForeground: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.58)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function open() { controller.show() }
  function close() { controller.hide() }
  function toggle() { opened ? close() : open() }

  function switchPanel(direction) {
    if (bar && typeof bar.switchPanelFrom === "function")
      return bar.switchPanelFrom(barIdentity, direction)
    return false
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(330))
    contentHeight: Math.min(Style.space(390), availableCardHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent

      onMoveRequested: function(dx, dy) {
        if (!root.metronomeService) return
        if (dx !== 0) root.metronomeService.adjustBpm(dx)
        else if (dy !== 0) root.metronomeService.adjustBpm(-dy * 5)
      }
      onActivateRequested: if (root.metronomeService) root.metronomeService.toggle()
      onTextKey: function(value) {
        if ((value === "t" || value === "T") && root.metronomeService)
          root.metronomeService.registerTap()
      }
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(14)

        Row {
          width: parent.width

          Text {
            width: parent.width - statusLabel.width
            text: "Metronome"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }

          Text {
            id: statusLabel
            text: root.metronomeService && root.metronomeService.active ? "● PLAYING" : "STOPPED"
            color: root.metronomeService && root.metronomeService.active ? Color.accent : root.mutedForeground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Column {
          width: parent.width
          spacing: Style.space(2)

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: String(Math.round(tempoSlider.dragging
              ? tempoSlider.liveValue
              : (root.metronomeService ? root.metronomeService.bpm : 120)))
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Math.round(Style.font.displayLarge * 1.8)
            font.bold: true
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "BEATS PER MINUTE"
            color: root.mutedForeground
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
          }
        }

        PanelSlider {
          id: tempoSlider
          width: parent.width
          bar: root.bar
          value: root.metronomeService ? root.metronomeService.bpm : 120
          minimum: 30
          maximum: 240
          step: 1
          integer: true
          onReleased: function(next) {
            if (root.metronomeService) root.metronomeService.setBpm(next)
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(7)

          Repeater {
            model: [
              { label: "−5", delta: -5 },
              { label: "−1", delta: -1 },
              { label: "+1", delta: 1 },
              { label: "+5", delta: 5 }
            ]

            delegate: Button {
              required property var modelData
              width: (parent.width - parent.spacing * 3) / 4
              text: modelData.label
              bordered: true
              foreground: root.foreground
              background: root.bar ? root.bar.background : Color.background
              accent: Color.accent
              onClicked: if (root.metronomeService) root.metronomeService.adjustBpm(modelData.delta)
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: (parent.width - parent.spacing) / 2
            iconText: root.metronomeService && root.metronomeService.active ? "" : ""
            text: root.metronomeService && root.metronomeService.active ? "Stop" : "Start"
            bordered: true
            selected: !!root.metronomeService && root.metronomeService.active
            foreground: root.foreground
            background: root.bar ? root.bar.background : Color.background
            accent: Color.accent
            onClicked: if (root.metronomeService) root.metronomeService.toggle()
          }

          Button {
            width: (parent.width - parent.spacing) / 2
            iconText: "󰓅"
            text: root.metronomeService && root.metronomeService.tapCount > 1
              ? "Tap " + root.metronomeService.tapCount
              : "Tap tempo"
            bordered: true
            foreground: root.foreground
            background: root.bar ? root.bar.background : Color.background
            accent: Color.accent
            onClicked: if (root.metronomeService) root.metronomeService.registerTap()
          }
        }

        PanelSectionHeader {
          text: "BEATS PER BAR"
          foreground: root.foreground
          fontFamily: root.fontFamily
        }

        ButtonGroup {
          width: parent.width
          options: ["2", "3", "4", "6"]
          value: root.metronomeService ? String(root.metronomeService.beatsPerBar) : "4"
          foreground: root.foreground
          background: root.bar ? root.bar.background : Color.background
          accent: Color.accent
          fontFamily: root.fontFamily
          onChanged: function(next) {
            if (root.metronomeService) root.metronomeService.setBeatsPerBar(Number(next))
          }
        }

        Text {
          visible: !!root.metronomeService && root.metronomeService.errorText !== ""
          width: parent.width
          text: root.metronomeService ? root.metronomeService.errorText : ""
          color: Color.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          wrapMode: Text.Wrap
        }

        Text {
          width: parent.width
          text: "Scroll the bar icon to fine-tune · right-click to start or stop"
          color: root.mutedForeground
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.Wrap
        }
      }
    }
  }
}
