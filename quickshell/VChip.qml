import QtQuick

Rectangle {
    id: c
    property var segments: []
    property bool dim: false
    property int fontSize: 13
    signal clicked()
    signal rightClicked()
    signal scrolled(real dy)

    readonly property bool solid: Settings.moduleOpacity > 60
    readonly property color ink: Colors.light ? Qt.darker(Colors.accent, 1.7) : Colors.accent

    width: Settings.chipH
    height: col.implicitHeight + 14
    radius: Settings.moduleRadius
    color: ma.containsMouse ? Colors.accent : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10)
    opacity: dim ? 0.55 : 1
    Behavior on color { ColorAnimation { duration: Math.round(150 * Settings.animMul) } }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 2
        Repeater {
            model: c.segments
            Text {
                required property var modelData
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.t
                font.family: Settings.fontFamily
                font.pixelSize: Math.round((modelData.s ? modelData.s : c.fontSize) * Settings.fontScale * Settings.bs)
                color: (ma.containsMouse || c.solid) ? Colors.onAccent
                     : (modelData.c ? modelData.c : (modelData.a ? c.ink : Colors.text))
            }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => { if (mouse.button === Qt.RightButton) c.rightClicked(); else c.clicked() }
        onWheel: wheel => c.scrolled(wheel.angleDelta.y)
    }
}
