import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  WlrLayershell.layer: WlrLayer.Bottom
  exclusionMode: ExclusionMode.Ignore

  anchors {
    left: Pos.p === "top" || Pos.p === "bottom"
    top: Pos.p !== "top"
    bottom: Pos.p === "top"
  }
  margins {
    left: 60 + (Pos.p === "left" ? 16 : 0)
    top: 60
    bottom: 60
  }

  implicitWidth: 520
  implicitHeight: 140
  color: "transparent"

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Column {
    width: parent.width
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    spacing: 4

    Text {
      text: Qt.formatDateTime(clock.date, "HH:mm:ss")
      color: Colors.accent
      width: parent.width
      horizontalAlignment: Pos.vert ? Text.AlignHCenter : Text.AlignLeft
      font.family: Settings.fontFamily
      font.pixelSize: Math.round(80 * Settings.fontScale)
      font.weight: Font.Light
    }

    Text {
      text: clock.date.toLocaleDateString(Qt.locale("ja_JP"), "yyyy年M月d日 dddd")
      color: Colors.accent
      width: parent.width
      horizontalAlignment: Pos.vert ? Text.AlignHCenter : Text.AlignLeft
      font.family: Settings.fontFamily
      font.pixelSize: Math.round(20 * Settings.fontScale)
    }
  }
}
