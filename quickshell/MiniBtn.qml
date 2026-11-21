import QtQuick

Rectangle {
    id: root
    property string text: ""
    property bool active: false
    signal clicked()

    implicitWidth: lbl.implicitWidth + 16
    implicitHeight: 24
    radius: 5
    color: active || ma.containsMouse ? Colors.accent
         : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10)
    Behavior on color { ColorAnimation { duration: Math.round(150 * Settings.animMul) } }

    Text {
        id: lbl
        anchors.centerIn: parent
        text: root.text
        color: root.active || ma.containsMouse ? Colors.onAccent : Colors.text
        font.family: Settings.fontFamily
        font.pixelSize: 12
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
