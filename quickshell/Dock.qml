import QtQuick
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    Scope {
        id: sc
        required property var modelData

        readonly property string pos: Settings.dockPosition
        readonly property bool vert: pos === "left" || pos === "right"
        readonly property bool on: Settings.dockShow
        readonly property bool auto: Settings.dockAutoHide
        property bool shown: false
        // se a barra esta na mesma borda, a dock fica depois dela
        readonly property int edgeGap: Pos.p === pos ? Pos.gap : 10

        Timer { id: hideT; interval: 600; onTriggered: sc.shown = false }

        // ---------- itens: fixados + abertos ----------
        property var items: []
        property string sig: ""

        function stripDesktop(id) { return (id || "").toLowerCase().replace(/\.desktop$/, "") }
        function lookup(name) {
            if (!name) return null
            try { return DesktopEntries.heuristicLookup(name) } catch (e) { return null }
        }
        function rebuild() {
            const tops = ToplevelManager.toplevels.values
            const byApp = {}
            let activeId = ""
            for (let i = 0; i < tops.length; i++) {
                const t = tops[i]
                const k = (t.appId || "").toLowerCase()
                if (k === "") continue
                if (!byApp[k]) byApp[k] = []
                byApp[k].push(t)
                if (t.activated) activeId = k
            }
            const pins = Array.from(Settings.dockPinned)
            const out = []
            const used = {}
            for (let i = 0; i < pins.length; i++) {
                const pin = String(pins[i]).toLowerCase()
                const e = lookup(pin)
                const cands = [pin]
                if (e) {
                    cands.push(stripDesktop(e.id))
                    if (e.startupClass) cands.push(String(e.startupClass).toLowerCase())
                }
                let run = [], runKey = ""
                for (let c = 0; c < cands.length; c++)
                    if (byApp[cands[c]]) { run = byApp[cands[c]]; runKey = cands[c]; break }
                if (!e && run.length === 0) continue
                if (runKey) used[runKey] = true
                out.push({ key: pin, pin: pin, name: e ? e.name : pin, icon: e ? e.icon : pin,
                           entry: e, tops: run, pinned: true, active: runKey !== "" && runKey === activeId })
            }
            for (const k in byApp) {
                if (used[k]) continue
                const e = lookup(k)
                out.push({ key: k, pin: e ? stripDesktop(e.id) : k, name: e ? e.name : k, icon: e ? e.icon : k,
                           entry: e, tops: byApp[k], pinned: false, active: k === activeId })
            }
            const s = out.map(o => o.key + ":" + o.tops.length + ":" + (o.active ? 1 : 0)).join("|") + "#" + pins.join(",")
            if (s !== sig) { sig = s; items = out }
        }
        Timer { interval: 400; running: sc.on; repeat: true; triggeredOnStart: true; onTriggered: sc.rebuild() }

        function activateItem(item) {
            if (item.tops.length > 0) {
                let idx = 0
                for (let i = 0; i < item.tops.length; i++)
                    if (item.tops[i].activated) { idx = (i + 1) % item.tops.length; break }
                item.tops[idx].activate()
            } else if (item.entry) {
                item.entry.execute()
            }
        }
        function togglePin(item) {
            const pins = Array.from(Settings.dockPinned)
            const idx = pins.map(p => String(p).toLowerCase()).indexOf(item.pin)
            if (idx >= 0) pins.splice(idx, 1); else pins.push(item.pin)
            Settings.dockPinned = pins
        }

        // ---------- faixa que acorda a dock ----------
        PanelWindow {
            id: strip
            screen: sc.modelData
            visible: sc.on && sc.auto
            exclusiveZone: 0
            color: "transparent"
            anchors {
                top: sc.pos === "top"
                bottom: sc.pos === "bottom"
                left: sc.pos === "left"
                right: sc.pos === "right"
            }
            implicitWidth: sc.vert ? 3 : 320
            implicitHeight: sc.vert ? 320 : 3
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { sc.shown = true; hideT.stop() }
                onExited: hideT.restart()
            }
        }

        // ---------- icone ----------
        Component {
            id: iconDelegate
            Item {
                id: di
                required property var modelData
                width: 48
                height: 48
                readonly property bool hov: ma.containsMouse
                readonly property string src: {
                    const ic = modelData.icon || ""
                    if (ic.indexOf("/") === 0) return "file://" + ic
                    return Quickshell.iconPath(ic, true) || Quickshell.iconPath(modelData.key, true)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(Settings.moduleRadius, 24)
                    color: modelData.active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)
                         : (di.hov ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18) : "transparent")
                    Behavior on color { ColorAnimation { duration: Math.round(120 * Settings.animMul) } }
                }
                Image {
                    id: img
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    sourceSize.width: 64
                    sourceSize.height: 64
                    source: di.src
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready
                    scale: di.hov ? 1.2 : 1.0
                    Behavior on scale { NumberAnimation { duration: Math.round(120 * Settings.animMul) } }
                }
                Text {
                    anchors.centerIn: parent
                    visible: img.status !== Image.Ready
                    text: "\uf2d0"
                    font.family: Settings.fontFamily
                    font.pixelSize: 24
                    color: Colors.text
                }
                // marca de "aberto"
                Rectangle {
                    visible: modelData.tops.length > 0
                    width: sc.vert ? 3 : 8
                    height: sc.vert ? 8 : 3
                    radius: 2
                    color: Colors.accent
                    x: sc.vert ? (sc.pos === "left" ? 1 : parent.width - width - 1) : (parent.width - width) / 2
                    y: sc.vert ? (parent.height - height) / 2 : parent.height - height - 1
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) { if (modelData.entry) modelData.entry.execute() }
                        else if (mouse.button === Qt.RightButton) sc.togglePin(modelData)
                        else sc.activateItem(modelData)
                    }
                }
            }
        }

        // ---------- a dock ----------
        PanelWindow {
            id: dock
            screen: sc.modelData
            visible: sc.on && (!sc.auto || sc.shown)
            exclusiveZone: 0
            color: "transparent"
            anchors {
                top: sc.pos === "top"
                bottom: sc.pos === "bottom"
                left: sc.pos === "left"
                right: sc.pos === "right"
            }
            margins { top: sc.edgeGap; bottom: sc.edgeGap; left: sc.edgeGap; right: sc.edgeGap }
            implicitWidth: sc.vert ? 68 : hbox.implicitWidth + 24
            implicitHeight: sc.vert ? vbox.implicitHeight + 24 : 68

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
                border.width: 2
                border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10 * Settings.barOpacity)

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) { sc.shown = true; hideT.stop() }
                        else hideT.restart()
                    }
                }

                Row {
                    id: hbox
                    visible: !sc.vert
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater { model: sc.items; delegate: iconDelegate }
                }
                Column {
                    id: vbox
                    visible: sc.vert
                    anchors.centerIn: parent
                    spacing: 8
                    Repeater { model: sc.items; delegate: iconDelegate }
                }
            }
        }
    }
}
