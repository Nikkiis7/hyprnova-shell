import QtQuick

Item {
  id: root
  property real ratio: 0
  property color accent: Colors.accent
  height: 5

  Rectangle {
    anchors.fill: parent
    radius: 3
    color: Colors.surfaceHi

    Rectangle {
      height: parent.height
      radius: 3
      width: parent.width * Math.max(0, Math.min(1, root.ratio))
      color: root.ratio > 0.85 ? "#ff6b9d" : root.accent
      Behavior on width { NumberAnimation { duration: Math.round(300 * Settings.animMul); easing.type: Easing.OutCubic } }
    }
  }
}
