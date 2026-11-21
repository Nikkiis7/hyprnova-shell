import QtQuick

Rectangle {
    id: c
    property bool vertical: false
    signal clicked()

    readonly property string style: Settings.logoStyle
    readonly property color ink: Colors.light ? Qt.darker(Colors.accent, 1.7) : Colors.accent
    readonly property bool solid: Settings.moduleOpacity > 60
    readonly property color fg: (ma.containsMouse || solid) ? Colors.onAccent : ink

    width: vertical ? Settings.chipH : (Settings.mini ? 36 : 44)
    height: Settings.chipH
    radius: Settings.moduleRadius
    color: ma.containsMouse ? Colors.accent : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, Settings.moduleOpacity / 100)
    Behavior on color { ColorAnimation { duration: Math.round(150 * Settings.animMul) } }

    Text {
        anchors.centerIn: parent
        text: c.style === "hyprland" ? "\uf359" : (c.style === "hyprnova" ? "\ue22e" : "\uf303")
        font.family: Settings.fontFamily
        font.pixelSize: Math.round(20 * Settings.fontScale * Settings.bs)
        color: c.fg
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: c.clicked()
    }
}
