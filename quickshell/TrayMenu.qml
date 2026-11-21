import QtQuick
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: root
    property var handle: null
    property var parentWin: null
    property real px: 0
    property real py: 0
    function open() { root.visible = !root.visible }

    anchor.window: parentWin
    anchor.rect.x: Pos.p === "left" ? 56 : (Pos.p === "right" ? -implicitWidth - 4 : px)
    anchor.rect.y: Pos.p === "bottom" ? -implicitHeight - 4 : (Pos.vert ? py : 52)
    implicitWidth: 240
    implicitHeight: col.implicitHeight + 16
    visible: false
    color: "transparent"

    QsMenuOpener { id: opener; menu: root.handle }

    HyprlandFocusGrab {
        windows: [root]
        active: root.visible
        onCleared: root.visible = false
    }

    Timer {
        interval: 800
        running: root.visible && !hov.hovered
        onTriggered: root.visible = false
    }

    Rectangle {
        anchors.fill: parent
        radius: Settings.wRadius
        color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
        border.width: Settings.wBorder
        border.color: Colors.border

        HoverHandler { id: hov }

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
            spacing: 2
            Repeater {
                model: opener.children
                delegate: Rectangle {
                    id: row
                    required property var modelData
                    width: col.width
                    height: modelData.isSeparator ? 9 : 30
                    radius: 5
                    color: !modelData.isSeparator && modelData.enabled && ma.containsMouse ? Colors.accent : "transparent"
                    Behavior on color { ColorAnimation { duration: Math.round(150 * Settings.animMul) } }

                    Rectangle {
                        visible: row.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: 1
                        color: Colors.border
                    }
                    Text {
                        visible: !row.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        elide: Text.ElideRight
                        text: (row.modelData.text || "").replace(/&/g, "")
                        color: !row.modelData.enabled ? "#73ffffff" : ma.containsMouse ? Colors.onAccent : "#ffffff"
                        font.family: Settings.wFontFamily
                        font.pixelSize: Math.round(15 * Settings.wScale)
                    }
                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !row.modelData.isSeparator && row.modelData.enabled
                        onClicked: {
                            row.modelData.triggered()
                            root.visible = false
                        }
                    }
                }
            }
        }
    }
}
