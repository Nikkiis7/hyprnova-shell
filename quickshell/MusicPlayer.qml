import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io
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
    target: "musicplayer"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return; win.open = !win.open }
  }

  // prefere o player que está tocando; senão o primeiro da lista
  property var lastActive: null

  property var player: {
    const list = Mpris.players.values
    for (let i = 0; i < list.length; i++) {
      if (list[i].isPlaying) return list[i]
    }
    if (lastActive && list.indexOf(lastActive) >= 0) return lastActive
    return list.length > 0 ? list[0] : null
  }

  onPlayerChanged: if (player && player.isPlaying) lastActive = player

  property bool open: false
  property bool shown: player !== null && open

  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: Pos.a("top", "end")
    bottom: Pos.a("bottom", "end")
    left: Pos.a("left", "end")
    right: Pos.a("right", "end")
  }
  margins {
    top: Pos.m("top", "end", 184, "end")
    bottom: Pos.m("bottom", "end", 184, "end")
    left: Pos.m("left", "end", 184, "end")
    right: Pos.m("right", "end", 184, "end")
  }

  implicitWidth: 325
  implicitHeight: 132
  color: "transparent"

  // atualiza a barra de progresso enquanto toca
  Timer {
    interval: 1000
    repeat: true
    running: win.player !== null && win.player.isPlaying
    onTriggered: win.player.positionChanged()
  }

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: win.open = false
  }

  Rectangle {
    id: card
    width: parent.width
    height: 104
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

    Row {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 12

      Rectangle {
        width: 80
        height: 80
        radius: 8
        color: Colors.surface

        Text {
          anchors.centerIn: parent
          text: Tr.t("󰎆")
          color: win.accent
          font.family: win.fonte
          font.pixelSize: Math.round(28 * Settings.wScale)
        }

        Image {
          anchors.fill: parent
          source: win.player ? win.player.trackArtUrl : ""
          fillMode: Image.PreserveAspectCrop
        }
      }

      Column {
        width: parent.width - 80 - 12
        spacing: 6

        Text {
          width: parent.width
          text: win.player ? win.player.trackTitle : ""
          color: Colors.text
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          text: win.player ? win.player.trackArtist : ""
          color: Colors.textDim
          font.family: win.fonte
          font.pixelSize: Math.round(12 * Settings.wScale)
          elide: Text.ElideRight
        }

        Seekbar {
          width: parent.width
          player: win.player
          accent: win.accent
        }

        Row {
          spacing: 8

          Btn {
            icon: "󰒮"
            accent: win.accent
            fonte: win.fonte
            onClicked: if (win.player) win.player.previous()
          }

          Btn {
            icon: (win.player && win.player.isPlaying) ? "󰏤" : "󰐊"
            accent: win.accent
            fonte: win.fonte
            onClicked: if (win.player) win.player.togglePlaying()
          }

          Btn {
            icon: "󰒭"
            accent: win.accent
            fonte: win.fonte
            onClicked: if (win.player) win.player.next()
          }
        }
      }
    }
  }
}
