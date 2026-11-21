import QtQuick

Rectangle {
    id: c
    property var segments: []
    property int hpad: 8
    property int fontSize: 20
    property bool dim: false
    property string extra: ""
    signal clicked()
    signal rightClicked()
    signal scrolled(real dy)

    readonly property bool hov: ma.containsMouse
    readonly property bool solid: Settings.moduleOpacity > 60
    readonly property color ink: Colors.light ? Qt.darker(Colors.accent, 1.7) : Colors.accent

    height: Settings.chipH
    width: hpad * 2 + row.implicitWidth + extraBox.width
    radius: Settings.moduleRadius
    color: hov ? Colors.accent : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, Settings.moduleOpacity / 100)
    opacity: dim ? 0.55 : 1
    Behavior on color { ColorAnimation { duration: Math.round(150 * Settings.animMul) } }

    Row {
        id: row
        x: c.hpad
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Repeater {
            model: c.segments
            Text {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.t
                font.family: Settings.fontFamily
                font.pixelSize: Math.round((modelData.s ? modelData.s : c.fontSize) * Settings.fontScale * Settings.bs)
                color: (c.hov || c.solid) ? Colors.onAccent
                     : (modelData.c ? modelData.c : (modelData.a ? c.ink : Colors.text))
            }
        }
    }

    Item {
        id: extraBox
        anchors.left: row.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        clip: true
        width: (c.hov && c.extra !== "") ? extraText.implicitWidth : 0
        Behavior on width { NumberAnimation { duration: Math.round(200 * Settings.animMul); easing.type: Easing.OutCubic } }
        Text {
            id: extraText
            anchors.verticalCenter: parent.verticalCenter
            text: c.extra
            font.family: Settings.fontFamily
            font.pixelSize: Math.round(c.fontSize * Settings.fontScale * Settings.bs)
            color: (c.hov || c.solid) ? Colors.onAccent : Colors.text
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
