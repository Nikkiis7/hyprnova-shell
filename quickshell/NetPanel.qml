import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root
    property bool open: false
    property real closedAt: 0
    property var nets: []
    property var known: ({})
    property bool wifiOn: true
    property string status: ""
    property string conn: "Verificando..."
    property string ask: ""

    IpcHandler {
        target: "network"
        function toggle(): void {
            if (!root.open && Date.now() - root.closedAt < 400) return
            root.open = !root.open
            if (root.open) root.refresh()
        }
    }

    function close() { open = false; closedAt = Date.now() }
    function refresh() { listP.running = true; knownP.running = true; radioP.running = true; devP.running = true }
    function act(args) { actP.command = args; actP.running = true }

    Process {
        id: listP
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {}, out = []
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    if (lines[i] === "") continue
                    const p = lines[i].split(":")
                    const ssid = p.slice(3).join(":").replace(/\\:/g, ":")
                    if (ssid === "" || seen[ssid]) continue
                    seen[ssid] = true
                    out.push({ ssid: ssid, signal: parseInt(p[1]) || 0, sec: p[2], used: p[0] === "*" })
                }
                out.sort((a, b) => (b.used - a.used) || (b.signal - a.signal))
                root.nets = out
            }
        }
    }
    Process {
        id: knownP
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const k = {}, l = text.split("\n")
                for (let i = 0; i < l.length; i++) if (l[i] !== "") k[l[i]] = true
                root.known = k
            }
        }
    }
    Process {
        id: radioP
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.wifiOn = text.trim() === "enabled" }
    }
    Process {
        id: devP
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.split("\n")
                let r = "Sem conexão"
                for (let i = 0; i < l.length; i++) {
                    const p = l[i].split(":")
                    if (p[1] === "connected" && (p[0] === "wifi" || p[0] === "ethernet")) {
                        r = (p[0] === "wifi" ? "Wi-Fi: " : "Cabo: ") + p.slice(2).join(":"); break
                    }
                }
                root.conn = r
            }
        }
    }
    Process {
        id: actP
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") root.status = text.trim() }
        stderr: StdioCollector { onStreamFinished: if (text.trim() !== "") root.status = text.trim() }
        onExited: refreshT.restart()
    }
    Process { id: editP; command: ["sh", "-c", "command -v nm-connection-editor >/dev/null && exec nm-connection-editor || exec kitty -e nmtui"] }
    Timer { id: refreshT; interval: 800; onTriggered: root.refresh() }
    Timer { interval: 6000; running: root.open; repeat: true; onTriggered: root.refresh() }

    PanelWindow {
        id: win
        visible: root.open
        color: "transparent"
        exclusiveZone: 0
        implicitWidth: 380
        implicitHeight: 470
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: Pos.a("top", "b"); bottom: Pos.a("bottom", "b")
            left: Pos.a("left", "b"); right: Pos.a("right", "b")
        }
        margins {
            top: Pos.m("top", "b", 14); bottom: Pos.m("bottom", "b", 14)
            left: Pos.m("left", "b", 14); right: Pos.m("right", "b", 14)
        }

        HyprlandFocusGrab {
            windows: [win]
            active: win.visible
            onCleared: root.close()
        }

        Rectangle {
            anchors.fill: parent
            radius: Settings.wRadius
            color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
            border.width: Settings.wBorder
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.close()
            }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Item {
                    width: parent.width; height: 34
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Tr.t("\uf1eb  Rede")
                        color: Colors.text
                        font.family: Settings.wFontFamily
                        font.pixelSize: Math.round(17 * Settings.wScale)
                        font.bold: true
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 52; height: 26; radius: 13
                        color: root.wifiOn ? Colors.accent : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.2)
                        Rectangle {
                            width: 20; height: 20; radius: 10; y: 3
                            x: root.wifiOn ? 29 : 3
                            color: root.wifiOn ? Colors.onAccent : Colors.text
                            Behavior on x { NumberAnimation { duration: Math.round(120 * Settings.animMul) } }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.act(["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"])
                        }
                    }
                }

                Text {
                    width: parent.width; elide: Text.ElideRight
                    text: root.conn
                    color: Colors.text; opacity: 0.7
                    font.family: Settings.wFontFamily
                    font.pixelSize: Math.round(12 * Settings.wScale)
                }

                ListView {
                    width: parent.width
                    height: 470 - 32 - 34 - 20 - 32 - 40 - (root.ask !== "" ? 50 : 0)
                    clip: true; spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.wifiOn ? root.nets : []
                    delegate: Rectangle {
                        id: nr
                        required property var modelData
                        width: ListView.view.width; height: 42
                        radius: Math.min(Settings.wRadius, 12)
                        color: modelData.used ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.3)
                             : (ma.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14) : "transparent")
                        Text {
                            x: 12; anchors.verticalCenter: parent.verticalCenter
                            text: Tr.t("\uf1eb")
                            color: nr.modelData.used ? Colors.accent : Colors.text
                            opacity: 0.4 + 0.6 * nr.modelData.signal / 100
                            font.family: Settings.wFontFamily; font.pixelSize: 16
                        }
                        Text {
                            x: 40; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 120; elide: Text.ElideRight
                            text: nr.modelData.ssid
                            color: Colors.text
                            font.family: Settings.wFontFamily
                            font.pixelSize: Math.round(14 * Settings.wScale)
                        }
                        Text {
                            anchors.right: parent.right; anchors.rightMargin: 12; anchors.verticalCenter: parent.verticalCenter
                            text: (nr.modelData.sec !== "" && nr.modelData.sec !== "--" ? "\uf023  " : "") + nr.modelData.signal + "%"
                            color: Colors.text; opacity: 0.6
                            font.family: Settings.wFontFamily
                            font.pixelSize: Math.round(12 * Settings.wScale)
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const n = nr.modelData
                                if (n.used) { root.act(["nmcli", "connection", "down", "id", n.ssid]); return }
                                const isOpen = n.sec === "" || n.sec === "--"
                                if (isOpen || root.known[n.ssid]) { root.ask = ""; root.status = "Conectando..."; root.act(["nmcli", "device", "wifi", "connect", n.ssid]) }
                                else { root.ask = n.ssid; pw.text = ""; pw.forceActiveFocus() }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.ask !== ""
                    width: parent.width; height: 40; radius: 8
                    color: Colors.surface
                    border.width: 1; border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5)
                    TextInput {
                        id: pw
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Colors.text; font.pixelSize: 14; clip: true
                        Keys.onEscapePressed: root.ask = ""
                        onAccepted: { root.status = "Conectando..."; root.act(["nmcli", "device", "wifi", "connect", root.ask, "password", text]); root.ask = "" }
                        Text {
                            visible: pw.text === ""
                            text: "Senha de " + root.ask + " (Enter)"
                            color: Colors.text; opacity: 0.45; font.pixelSize: 13
                        }
                    }
                }

                Item {
                    width: parent.width; height: 32
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 170; elide: Text.ElideRight
                        text: root.status
                        color: Colors.text; opacity: 0.6
                        font.family: Settings.wFontFamily; font.pixelSize: 11
                    }
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Rectangle {
                            width: 74; height: 30; radius: 8; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                            Text { anchors.centerIn: parent; text: Tr.t("Atualizar"); color: Colors.text; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.act(["nmcli", "device", "wifi", "rescan"]) }
                        }
                        Rectangle {
                            width: 74; height: 30; radius: 8; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                            Text { anchors.centerIn: parent; text: Tr.t("Avançado"); color: Colors.text; font.pixelSize: 12 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { editP.running = true; root.close() } }
                        }
                    }
                }
            }
        }
    }
}
