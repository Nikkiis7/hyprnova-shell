import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: win
    visible: Notifs.popups.length > 0
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: Settings.notifPosition.indexOf("top") === 0
        bottom: Settings.notifPosition.indexOf("bottom") === 0
        left: Settings.notifPosition.indexOf("left") >= 0
        right: Settings.notifPosition.indexOf("right") >= 0
    }
    margins { top: Pos.nm("top"); bottom: Pos.nm("bottom"); left: Pos.nm("left"); right: Pos.nm("right") }
    implicitWidth: 360
    implicitHeight: col.implicitHeight + 6
    color: "transparent"

    Column {
        id: col
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups

            delegate: Item {
                id: it
                required property int modelData
                readonly property var n: Notifs.find(modelData)
                readonly property bool crit: n !== null && n.urgency === NotificationUrgency.Critical
                readonly property int timeout: Notifs.remaining(modelData)

                visible: n !== null
                width: col.width
                height: visible ? card.height : 0

                Rectangle {
                    id: card
                    width: parent.width
                    height: inner.implicitHeight + 24
                    radius: Settings.wRadius
                    color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
                    border.width: Settings.wBorder
                    border.color: it.crit ? "#ff6b9d" : Colors.border
                    clip: true
                    opacity: 0
                    x: 40
                    Component.onCompleted: { opacity = 1; x = 0 }
                    Behavior on opacity { NumberAnimation { duration: Math.round(350 * Settings.animMul); easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: Math.round(350 * Settings.animMul); easing.type: Easing.OutCubic } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifs.hidePopup(it.modelData)
                    }

                    Row {
                        id: inner
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 10

                        Image {
                            id: pic
                            visible: source != ""
                            width: visible ? 40 : 0
                            height: 40
                            fillMode: Image.PreserveAspectFit
                            sourceSize.width: 40
                            sourceSize.height: 40
                            source: it.n
                                ? (it.n.image ? it.n.image
                                   : it.n.appIcon ? Quickshell.iconPath(it.n.appIcon, true) : "")
                                : ""
                        }

                        Column {
                            width: parent.width - (pic.visible ? 50 : 0) - 30
                            spacing: 2

                            Text {
                                width: parent.width
                                text: it.n ? it.n.appName : ""
                                color: Colors.textFaint
                                font.family: Settings.wFontFamily
                                font.pixelSize: Math.round(11 * Settings.wScale)
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: it.n ? it.n.summary : ""
                                color: Colors.text
                                font.family: Settings.wFontFamily
                                font.pixelSize: Math.round(14 * Settings.wScale)
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: text !== ""
                                width: parent.width
                                text: it.n ? it.n.body : ""
                                color: Colors.textDim
                                font.family: Settings.wFontFamily
                                font.pixelSize: Math.round(12 * Settings.wScale)
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }
                            Row {
                                spacing: 6
                                Repeater {
                                    model: it.n ? it.n.actions : []
                                    MiniBtn {
                                        required property var modelData
                                        text: modelData.text
                                        onClicked: {
                                            modelData.invoke()
                                            Notifs.hidePopup(it.modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MiniBtn {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        implicitHeight: 22
                        text: "\uf00d"
                        onClicked: Notifs.hidePopup(it.modelData)
                    }

                    Rectangle {
                        id: bar
                        visible: !it.crit
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        height: 2
                        color: Colors.accent
                        width: card.width
                        NumberAnimation on width {
                            running: !it.crit
                            from: card.width * Notifs.fraction(it.modelData)
                            to: 0
                            duration: it.timeout
                        }
                    }
                }
            }
        }
    }
}
