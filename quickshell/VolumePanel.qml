import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Hyprland
import QtQuick

PanelWindow {
  id: win

  property real closedAt: 0

  HyprlandFocusGrab {
    windows: [win]
    active: win.open
    onCleared: {
      win.open = false
      win.closedAt = Date.now()
    }
  }

  IpcHandler {
    target: "volume"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return; win.open = !win.open }
  }

  PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

  property var sink: Pipewire.defaultAudioSink
  property real vol: (sink && sink.audio) ? sink.audio.volume : 0
  property bool muted: (sink && sink.audio) ? sink.audio.muted : false

  property bool open: false
  property bool shown: open

  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily

  function setVol(v) {
    if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v))
  }

  function toggleMute() {
    if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
  }

  function iconFor() {
    if (muted || vol <= 0) return "󰖁"
    if (vol < 0.34) return "󰕿"
    if (vol < 0.67) return "󰖀"
    return "󰕾"
  }

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: Pos.a("top", Pos.grp(Settings.volumePlace, "end"))
    bottom: Pos.a("bottom", Pos.grp(Settings.volumePlace, "end"))
    left: Pos.a("left", Pos.grp(Settings.volumePlace, "end"))
    right: Pos.a("right", Pos.grp(Settings.volumePlace, "end"))
  }
  margins {
    top: Pos.m("top", Pos.grp(Settings.volumePlace, "end"), 170, "end")
    bottom: Pos.m("bottom", Pos.grp(Settings.volumePlace, "end"), 170, "end")
    left: Pos.m("left", Pos.grp(Settings.volumePlace, "end"), 170, "end")
    right: Pos.m("right", Pos.grp(Settings.volumePlace, "end"), 170, "end")
  }

  implicitWidth: 280
  implicitHeight: 130
  color: "transparent"

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: win.open = false
  }

  Rectangle {
    id: card
    width: parent.width
    height: 124
    radius: Settings.wRadius
    color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
    border.color: Colors.border
    border.width: Settings.wBorder

    opacity: win.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Math.round(450 * Settings.animMul); easing.type: Easing.OutCubic } }

    transform: Translate {
      y: win.shown ? 0 : -28
      Behavior on y { NumberAnimation { duration: Math.round(450 * Settings.animMul); easing.type: Easing.OutCubic } }
    }

    Column {
      anchors.fill: parent
      anchors.margins: 14
      spacing: 10

      Item {
        width: parent.width
        height: 28

        Btn {
          id: muteBtn
          anchors.left: parent.left
          icon: win.iconFor()
          accent: win.accent
          fonte: win.fonte
          onClicked: win.toggleMute()
        }

        Text {
          anchors.left: muteBtn.right
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          text: Tr.t("Volume")
          color: Colors.text
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: win.muted ? "mudo" : Math.round(win.vol * 100) + "%"
          color: win.muted ? Colors.textDim : win.accent
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true
        }
      }

      // controle deslizante
      Item {
        id: slider
        width: parent.width
        height: 20

        Rectangle {
          id: track
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: (area.containsMouse || area.pressed) ? 6 : 4
          radius: 3
          color: Colors.surfaceHi
          Behavior on height { NumberAnimation { duration: Math.round(120 * Settings.animMul) } }

          Rectangle {
            height: parent.height
            radius: 3
            color: win.muted ? Colors.textFaint : win.accent
            width: parent.width * Math.min(1, win.vol)
            Behavior on width { NumberAnimation { duration: Math.round(80 * Settings.animMul) } }
          }

          Rectangle {
            visible: area.containsMouse || area.pressed
            width: 12
            height: 12
            radius: 6
            color: win.accent
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, parent.width * win.vol - width / 2))
          }
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onPressed: (m) => win.setVol(m.x / width)
          onPositionChanged: (m) => { if (pressed) win.setVol(m.x / width) }
          onWheel: (w) => win.setVol(win.vol + (w.angleDelta.y > 0 ? 0.05 : -0.05))
        }
      }

      Text {
        width: parent.width
        text: win.sink ? (win.sink.description || win.sink.name) : "Sem saída de áudio"
        color: Colors.textDim
        font.family: win.fonte
        font.pixelSize: Math.round(12 * Settings.wScale)
        elide: Text.ElideRight
      }
    }
  }
}
