import QtQuick

Rectangle {
  id: btn
  property string icon: ""
  property color accent: Colors.accent
  property string fonte: "Iosevka Nerd Font"
  signal clicked()

  width: 34
  height: 28
  radius: 8
  color: area.containsMouse ? Colors.surfaceHi : Colors.surface
  Behavior on color { ColorAnimation { duration: Math.round(150 * Settings.animMul) } }

  Text {
    anchors.centerIn: parent
    text: btn.icon
    color: btn.accent
    font.family: btn.fonte
    font.pixelSize: 16
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    onClicked: btn.clicked()
  }
}
