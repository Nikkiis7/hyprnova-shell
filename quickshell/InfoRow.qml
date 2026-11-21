import QtQuick

Item {
  id: root
  property string label: ""
  property string value: ""
  property string fonte: Settings.wFontFamily
  property color accent: Colors.accent
  property bool strong: false
  height: 16

  Text {
    anchors.left: parent.left
    anchors.right: valueText.left
    anchors.rightMargin: 8
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: Colors.textDim
    font.family: root.fonte
    font.pixelSize: Math.round(12 * Settings.wScale)
    elide: Text.ElideRight
  }

  Text {
    id: valueText
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    text: root.value
    color: root.strong ? root.accent : Colors.text
    font.family: root.fonte
    font.pixelSize: Math.round(12 * Settings.wScale)
    font.bold: root.strong
  }
}
