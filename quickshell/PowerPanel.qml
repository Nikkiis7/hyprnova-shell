import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

PanelWindow {
  id: win

  property real closedAt: 0
  property string pending: ""

  HyprlandFocusGrab {
    windows: [win]
    active: win.open
    onCleared: {
      win.open = false
      win.closedAt = Date.now()
    }
  }

  IpcHandler {
    target: "power"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return
      win.open = !win.open
    }
  }

  property bool open: false
  onOpenChanged: if (!open) pending = ""

  property bool shown: open
  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily

  property var actions: [
    { key: "lock",     icon: "󰌾", label: Tr.t("Bloquear"),  confirm: false, danger: false, msg: "Bloquear a tela?" },
    { key: "suspend",  icon: "󰒲", label: Tr.t("Suspender"), confirm: true,  danger: false, msg: "Suspender o computador?" },
    { key: "logout",   icon: "󰍃", label: Tr.t("Sair"),      confirm: true,  danger: false, msg: "Encerrar a sessão?" },
    { key: "reboot",   icon: "󰜉", label: Tr.t("Reiniciar"), confirm: true,  danger: true,  msg: "Reiniciar o computador?" },
    { key: "poweroff", icon: "󰐥", label: Tr.t("Desligar"),  confirm: true,  danger: true,  msg: "Desligar o computador?" }
  ]

  function find(key) {
    for (let i = 0; i < actions.length; i++) {
      if (actions[i].key === key) return actions[i]
    }
    return null
  }

  function run(key) {
    if (key === "lock")          Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock"])
    else if (key === "suspend")  Quickshell.execDetached(["systemctl", "suspend"])
    else if (key === "logout")   Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.exit()"])
    else if (key === "reboot")   Quickshell.execDetached(["systemctl", "reboot"])
    else if (key === "poweroff") Quickshell.execDetached(["systemctl", "poweroff"])
    win.open = false
  }

  function choose(key) {
    const a = find(key)
    if (a && a.confirm) pending = key
    else run(key)
  }

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: win.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: Pos.a("top", Pos.grp(Settings.powerPlace, "end"))
    bottom: Pos.a("bottom", Pos.grp(Settings.powerPlace, "end"))
    left: Pos.a("left", Pos.grp(Settings.powerPlace, "end"))
    right: Pos.a("right", Pos.grp(Settings.powerPlace, "end"))
  }
  margins {
    top: Pos.m("top", Pos.grp(Settings.powerPlace, "end"), 15, "end")
    bottom: Pos.m("bottom", Pos.grp(Settings.powerPlace, "end"), 15, "end")
    left: Pos.m("left", Pos.grp(Settings.powerPlace, "end"), 15, "end")
    right: Pos.m("right", Pos.grp(Settings.powerPlace, "end"), 15, "end")
  }

  implicitWidth: 200
  implicitHeight: 230
  color: "transparent"

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: {
      if (win.pending !== "") win.pending = ""
      else win.open = false
    }
  }

  Rectangle {
    id: card
    width: parent.width
    height: win.pending === "" ? 212 : 140
    radius: Settings.wRadius
    color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
    border.color: Colors.border
    border.width: Settings.wBorder
    Behavior on height { NumberAnimation { duration: Math.round(200 * Settings.animMul); easing.type: Easing.OutCubic } }

    opacity: win.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Math.round(450 * Settings.animMul); easing.type: Easing.OutCubic } }

    transform: Translate {
      y: win.shown ? 0 : -28
      Behavior on y { NumberAnimation { duration: Math.round(450 * Settings.animMul); easing.type: Easing.OutCubic } }
    }

    // ---------- lista ----------
    Column {
      visible: win.pending === ""
      x: 8
      y: 8
      width: parent.width - 16
      spacing: 4

      Repeater {
        model: win.actions

        Rectangle {
          width: parent.width
          height: 36
          radius: 8
          color: rowArea.containsMouse ? win.accent : "transparent"
          Behavior on color { ColorAnimation { duration: Math.round(350 * Settings.animMul) } }

          Text {
            id: ico
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.icon
            color: rowArea.containsMouse ? Colors.onAccent : win.accent
            Behavior on color { ColorAnimation { duration: Math.round(350 * Settings.animMul) } }
            font.family: win.fonte
            font.pixelSize: Math.round(18 * Settings.wScale)
          }

          Text {
            anchors.left: ico.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.label
            color: rowArea.containsMouse ? Colors.onAccent : Colors.text
            Behavior on color { ColorAnimation { duration: Math.round(350 * Settings.animMul) } }
            font.family: win.fonte
            font.pixelSize: Math.round(13 * Settings.wScale)
          }

          MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.choose(modelData.key)
          }
        }
      }
    }

    // ---------- confirmação ----------
    Column {
      id: conf
      visible: win.pending !== ""
      x: 12
      y: 14
      width: parent.width - 24
      spacing: 14

      Column {
        width: conf.width
        spacing: 3

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          text: Tr.t("Tem certeza?")
          color: Colors.text
          font.family: win.fonte
          font.pixelSize: Math.round(15 * Settings.wScale)
          font.bold: true
        }

        Text {
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.WordWrap
          text: win.find(win.pending) ? win.find(win.pending).msg.replace("?", "") : ""
          color: Colors.textDim
          font.family: win.fonte
          font.pixelSize: Math.round(12 * Settings.wScale)
        }
      }

      Row {
        spacing: 8

        Rectangle {
          width: (conf.width - 8) / 2
          height: 40
          radius: 8
          color: cancelArea.containsMouse ? win.accent : Colors.surface
          Behavior on color { ColorAnimation { duration: Math.round(350 * Settings.animMul) } }

          Text {
            anchors.centerIn: parent
            text: Tr.t("Cancelar")
            color: cancelArea.containsMouse ? Colors.onAccent : Colors.text
            Behavior on color { ColorAnimation { duration: Math.round(350 * Settings.animMul) } }
            font.family: win.fonte
            font.pixelSize: Math.round(12 * Settings.wScale)
          }

          MouseArea {
            id: cancelArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.pending = ""
          }
        }

        Rectangle {
          width: (conf.width - 8) / 2
          height: 40
          radius: 8
          color: okArea.containsMouse ? Colors.accentLight : win.accent
          Behavior on color { ColorAnimation { duration: Math.round(350 * Settings.animMul) } }

          Text {
            anchors.centerIn: parent
            text: Tr.t("Confirmar")
            color: Colors.onAccent
            font.family: win.fonte
            font.pixelSize: Math.round(12 * Settings.wScale)
            font.bold: true
          }

          MouseArea {
            id: okArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.run(win.pending)
          }
        }
      }
    }
  }
}
