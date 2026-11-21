import QtQuick

Rectangle {
    id: root
    property string text: ""
    property color fg: Colors.text
    property bool active: false
    signal clicked()
    signal scrolled(int dy)

    implicitWidth: label.implicitWidth + 20
    implicitHeight: 26
    radius: 8
    color: active ? Colors.accent
         : ma.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.25)
         : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10)
    Behavior on color { ColorAnimation { duration: Math.round(150 * Settings.animMul) } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.active ? Colors.onAccent : root.fg
        font.family: Settings.fontFamily
        font.pixelSize: 14
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }
}
