import Quickshell
import Quickshell.Wayland
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
    target: "calendar"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return;
      if (!win.open) win.goToday()
      win.open = !win.open
    }
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  property bool open: false
  property bool shown: open

  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily

  property var meses: ["Janeiro", "Fevereiro", "Março", "Abril", "Maio", "Junho",
                       "Julho", "Agosto", "Setembro", "Outubro", "Novembro", "Dezembro"]
  property var dias: ["D", "S", "T", "Q", "Q", "S", "S"]

  property int viewYear: new Date().getFullYear()
  property int viewMonth: new Date().getMonth()
  property int firstOffset: new Date(viewYear, viewMonth, 1).getDay()

  function goToday() {
    const d = new Date()
    viewYear = d.getFullYear()
    viewMonth = d.getMonth()
  }

  function shift(n) {
    const d = new Date(viewYear, viewMonth + n, 1)
    viewYear = d.getFullYear()
    viewMonth = d.getMonth()
  }

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: Pos.a("top", Pos.grp(Settings.clockPlace, "end"))
    bottom: Pos.a("bottom", Pos.grp(Settings.clockPlace, "end"))
    left: Pos.a("left", Pos.grp(Settings.clockPlace, "end"))
    right: Pos.a("right", Pos.grp(Settings.clockPlace, "end"))
  }
  margins {
    top: Pos.m("top", Pos.grp(Settings.clockPlace, "end"), 63, "end")
    bottom: Pos.m("bottom", Pos.grp(Settings.clockPlace, "end"), 63, "end")
    left: Pos.m("left", Pos.grp(Settings.clockPlace, "end"), 63, "end")
    right: Pos.m("right", Pos.grp(Settings.clockPlace, "end"), 63, "end")
  }

  implicitWidth: 294
  implicitHeight: 290
  color: "transparent"

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: win.open = false
  }

  Rectangle {
    id: card
    width: parent.width
    height: 284
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
      spacing: 8

      Item {
        width: parent.width
        height: 28

        Btn {
          anchors.left: parent.left
          icon: "󰅁"
          accent: win.accent
          fonte: win.fonte
          onClicked: win.shift(-1)
        }

        Text {
          anchors.centerIn: parent
          text: win.meses[win.viewMonth] + " " + win.viewYear
          color: Colors.text
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: win.goToday()
          }
        }

        Btn {
          anchors.right: parent.right
          icon: "󰅂"
          accent: win.accent
          fonte: win.fonte
          onClicked: win.shift(1)
        }
      }

      Row {
        Repeater {
          model: 7
          Text {
            width: 38
            height: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: win.dias[index]
            color: Colors.textDim
            font.family: win.fonte
            font.pixelSize: Math.round(12 * Settings.wScale)
          }
        }
      }

      Grid {
        columns: 7

        Repeater {
          model: 42

          Rectangle {
            id: cell
            width: 38
            height: 32
            radius: 8

            property var cellDate: new Date(win.viewYear, win.viewMonth, 1 - win.firstOffset + index)
            property bool inMonth: cellDate.getMonth() === win.viewMonth
            property bool isToday: cellDate.getFullYear() === clock.date.getFullYear()
                                && cellDate.getMonth() === clock.date.getMonth()
                                && cellDate.getDate() === clock.date.getDate()

            color: isToday ? win.accent : (cellArea.containsMouse ? Colors.surfaceHi : "transparent")
            Behavior on color { ColorAnimation { duration: Math.round(120 * Settings.animMul) } }

            Text {
              anchors.centerIn: parent
              text: cell.cellDate.getDate()
              color: cell.isToday ? Colors.onAccent : (cell.inMonth ? Colors.text : Colors.textFaint)
              font.family: win.fonte
              font.pixelSize: Math.round(13 * Settings.wScale)
              font.bold: cell.isToday
            }

            MouseArea {
              id: cellArea
              anchors.fill: parent
              hoverEnabled: true
            }
          }
        }
      }
    }
  }
}
