import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: win

    property bool open: false
    property bool shown: open
    property real closedAt: 0
    property var swatches: [
        "#ff5c5c", "#ff9f5c", "#ffd75c", "#6be08a", "#3fe0c5", "#5cdcff", "#6b8cff", "#b48cff", "#ff7ac8", "#f0f0f5",
        "#ffadad", "#ffcfa3", "#fff0a3", "#b8f0c4", "#b3f5e8", "#aeeeff", "#b3c4ff", "#d9c2ff", "#ffc2e6", "#b0b0bc"
    ]
    property string fonte: Settings.wFontFamily

    function setOpen(v) {
        win.open = v
    }

    function apply(hex) {
        act.command = ["sh", "-c",
            'img="$(cat "$HOME/.cache/current-wallpaper")"; name="$(basename "$img")"; ' +
            'conf="$HOME/.config/wall-accents.conf"; touch "$conf"; ' +
            'grep -v "^$name " "$conf" > "$conf.tmp"; echo "$name $1" >> "$conf.tmp"; mv "$conf.tmp" "$conf"; ' +
            '"$HOME/.local/bin/waybar-color" "$1"', "sh", hex]
        act.running = true
        win.open = false
    }

    function useAuto() {
        act.command = ["sh", "-c",
            'img="$(cat "$HOME/.cache/current-wallpaper")"; name="$(basename "$img")"; ' +
            'conf="$HOME/.config/wall-accents.conf"; ' +
            '[ -f "$conf" ] && { grep -v "^$name " "$conf" > "$conf.tmp"; mv "$conf.tmp" "$conf"; }; ' +
            '"$HOME/.local/bin/wall-accent" "$img"']
        act.running = true
        win.open = false
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.open
        onCleared: {
            win.open = false
            win.closedAt = Date.now()
        }
    }

    IpcHandler {
        target: "wallcolors"
        function toggle(): void {
            if (!win.open && Date.now() - win.closedAt < 400) return
            win.setOpen(!win.open)
        }
        function show(): void { win.setOpen(true) }
    }

    Process {
        id: pal
        command: ["sh", "-c", '"$HOME/.local/bin/wall-accent" --palette "$(cat "$HOME/.cache/current-wallpaper")"']
        stdout: StdioCollector {
            onStreamFinished: win.swatches = this.text.trim().split("\n").filter(l => /^#[0-9a-fA-F]{6}$/.test(l))
        }
    }
    Process { id: act }

    Timer {
        interval: 12000
        running: win.open && !hov.hovered
        onTriggered: win.open = false
    }

    visible: shown || card.opacity > 0.01
    WlrLayershell.layer: WlrLayer.Top
    exclusionMode: ExclusionMode.Ignore
    anchors { top: Settings.barPosition === "top"; bottom: Settings.barPosition === "bottom"; left: Settings.barPosition === "left"; right: Settings.barPosition === "right" }
    margins { top: Pos.gap; bottom: Pos.gap; left: Pos.gap; right: Pos.gap }
    implicitWidth: card.width
    implicitHeight: card.height + 6
    color: "transparent"

    Rectangle {
        id: card
        width: content.implicitWidth + 32
        height: content.implicitHeight + 28
        radius: Settings.wRadius
        color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
        border.color: Colors.border
        border.width: Settings.wBorder

        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Math.round(350 * Settings.animMul); easing.type: Easing.OutCubic } }
        transform: Translate {
            y: win.shown ? 0 : -20
            Behavior on y { NumberAnimation { duration: Math.round(350 * Settings.animMul); easing.type: Easing.OutCubic } }
        }

        HoverHandler { id: hov }

        Column {
            id: content
            x: 16
            y: 14
            spacing: 10

            Text {
                text: Tr.t("Cor do tema")
                color: Colors.textDim
                font.family: win.fonte
                font.pixelSize: Math.round(12 * Settings.wScale)
            }

            Grid {
                columns: 10
                spacing: 10
                Repeater {
                    model: win.swatches
                    delegate: Rectangle {
                        id: sw
                        required property string modelData
                        readonly property bool selected:
                            modelData.toLowerCase() === Colors.accent.toString().toLowerCase()
                        width: 34
                        height: 34
                        radius: 17
                        color: modelData
                        border.width: selected ? 3 : 0
                        border.color: Colors.text
                        scale: swMa.containsMouse ? 1.15 : 1.0
                        Behavior on scale { NumberAnimation { duration: Math.round(150 * Settings.animMul); easing.type: Easing.OutCubic } }
                        MouseArea {
                            id: swMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.apply(sw.modelData)
                        }
                    }
                }
            }

            MiniBtn {
                text: Tr.t("Auto (do wallpaper)")
                onClicked: win.useAuto()
            }
        }
    }
}
