import QtQuick

Item {
  id: root
  property string label: ""
  property string value: ""
  property string fonte: Settings.wFontFamily
  height: 18

  Text {
    id: lbl
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: root.label
    color: Colors.textDim
    font.family: root.fonte
    font.pixelSize: Math.round(12 * Settings.wScale)
  }

  Text {
    anchors.left: lbl.right
    anchors.leftMargin: 12
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    horizontalAlignment: Text.AlignRight
    text: root.value
    color: Colors.text
    font.family: root.fonte
    font.pixelSize: Math.round(12 * Settings.wScale)
    elide: Text.ElideRight
  }
}
