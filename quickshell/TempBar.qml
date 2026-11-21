import QtQuick

Item {
    id: root
    property string fonte: Settings.wFontFamily
    property string label: ""
    property real temp: 0
    property real warn: 80
    height: 22

    Text {
        id: l
        text: root.label
        color: Colors.textDim
        font.family: root.fonte
        font.pixelSize: Math.round(13 * Settings.wScale)
        anchors.verticalCenter: parent.verticalCenter
        width: 40
    }
    Text {
        id: v
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        horizontalAlignment: Text.AlignRight
        text: root.temp > 0 ? root.temp + "°C" : "-"
        color: root.temp >= root.warn ? "#ff6b9d" : Colors.text
        font.family: root.fonte
        font.pixelSize: Math.round(13 * Settings.wScale)
    }
    Rectangle {
        id: track
        anchors.left: l.right
        anchors.right: v.left
        anchors.leftMargin: 6
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Colors.surface
        Rectangle {
            width: track.width * Math.min(1, root.temp / 100)
            height: parent.height
            radius: 3
            color: root.temp >= root.warn ? "#ff6b9d" : Colors.accent
            Behavior on width { NumberAnimation { duration: Math.round(400 * Settings.animMul); easing.type: Easing.OutCubic } }
        }
    }
}
