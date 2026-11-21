import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.SystemTray

Variants {
    model: Quickshell.screens

    Scope {
        id: sc
        required property var modelData

        // ---- ocultar sozinha ----
        readonly property bool autoHide: Settings.autoHide
        property bool shown: false
        Timer { id: hideT; interval: 600; onTriggered: sc.shown = false }

        // faixa fina na borda da tela que "acorda" a barra
        PanelWindow {
            id: strip
            screen: sc.modelData
            visible: sc.autoHide
            exclusiveZone: 0
            color: "transparent"
            anchors {
                top: win.pos !== "bottom"
                bottom: win.pos !== "top"
                left: win.pos !== "right"
                right: win.pos !== "left"
            }
            implicitHeight: win.vert ? 0 : 3
            implicitWidth: win.vert ? 3 : 0
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { sc.shown = true; hideT.stop() }
                onExited: hideT.restart()
            }
        }

        PanelWindow {
            id: win
            screen: sc.modelData
            visible: !sc.autoHide || sc.shown

            // ---- posicao (topo / embaixo / esquerda / direita) ----
            readonly property string pos: Settings.barPosition
            readonly property bool vert: pos === "left" || pos === "right"
            readonly property int thick: Settings.mini ? 44 : 52
            readonly property int vertW: Settings.mini ? 44 : 52
            anchors {
                top: win.pos !== "bottom"
                bottom: win.pos !== "top"
                left: win.pos !== "right"
                right: win.pos !== "left"
            }
            readonly property int mg: Settings.barStyle === "docked" ? 0 : 10
            margins { top: win.mg; bottom: win.mg; left: win.mg; right: win.mg }
            implicitHeight: win.vert ? 0 : win.thick
            implicitWidth: win.vert ? win.vertW : 0
            exclusiveZone: sc.autoHide ? 0 : (win.vert ? win.vertW : win.thick)
            color: "transparent"

            // nomes dos alvos IPC dos seus paineis
            property var ipcTargets: ({
                logo: "archinfo", sys: "sysinfo", volume: "volume", music: "musicplayer",
                calendar: "calendar", power: "power", windows: "windows", network: "network"
            })
            function ipc(key) {
                ipcProc.command = ["quickshell", "ipc", "call", ipcTargets[key], "toggle"]
                ipcProc.running = true
            }
            Process { id: ipcProc }
            property bool netUp: false
            property string netType: ""
            Process {
                id: netProc
                command: ["sh", "-c", "nmcli -t -f TYPE,STATE device 2>/dev/null | grep ':connected$' | grep -v loopback | head -1"]
                stdout: StdioCollector {
                    onStreamFinished: { const t = text.trim(); win.netUp = t !== ""; win.netType = t.split(":")[0] }
                }
            }
            Timer { interval: 5000; running: Settings.netOn; repeat: true; triggeredOnStart: true; onTriggered: netProc.running = true }
            readonly property string netIcon: netType === "ethernet" ? "\uDB80\uDE00" : "\uf1eb"
            Process { id: wsProc }
            function cut(t, n) { return t.length > n ? t.slice(0, n) + "…" : t }

            SystemClock { id: clock; precision: SystemClock.Minutes }

            // ---- CPU / RAM ----
            property int cpu: 0
            property int ramUsed: 0
            property int ramTotal: 1
            property real prevIdle: 0
            property real prevTotal: 0
            readonly property int ramPct: Math.round(100 * ramUsed / ramTotal)
            Process {
                id: statProc
                command: ["sh", "-c", "head -1 /proc/stat; free -m | awk '/^Mem/{print $3, $2}'"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const lines = text.trim().split("\n")
                        const c = lines[0].trim().split(/\s+/).slice(1).map(Number)
                        const idle = c[3] + c[4]
                        const total = c.reduce((a, b) => a + b, 0)
                        if (win.prevTotal > 0)
                            win.cpu = Math.round(100 * (1 - (idle - win.prevIdle) / (total - win.prevTotal)))
                        win.prevIdle = idle
                        win.prevTotal = total
                        const m = lines[1].split(" ")
                        win.ramUsed = Number(m[0])
                        win.ramTotal = Number(m[1])
                    }
                }
            }
            Timer {
                interval: 2000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: statProc.running = true
            }

            // ---- volume ----
            readonly property var sink: Pipewire.defaultAudioSink
            PwObjectTracker { objects: [win.sink] }
            readonly property int vol: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
            readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
            function scrollVolume(dy) {
                if (win.sink && win.sink.audio)
                    win.sink.audio.volume = Math.max(0, Math.min(1, win.sink.audio.volume + (dy > 0 ? 0.05 : -0.05)))
            }

            // ---- musica / janela ----
            property var player: null
            function pickPlayer() {
                const ps = Mpris.players.values
                let cur = null, playingOne = null, fallback = null
                for (let i = 0; i < ps.length; i++) {
                    if (ps[i].playbackState === MprisPlaybackState.Playing) { playingOne = ps[i]; break }
                    if (ps[i] === player) cur = ps[i]
                    if (!fallback && ps[i].trackTitle) fallback = ps[i]
                }
                const next = playingOne || cur || fallback
                if (next !== player) player = next
            }
            Timer { interval: 300; running: true; repeat: true; triggeredOnStart: true; onTriggered: win.pickPlayer() }
            readonly property bool playing: player !== null && player.playbackState === MprisPlaybackState.Playing
            readonly property string musicTitle: {
                if (!player || !player.trackTitle) return "Sem título"
                return player.trackTitle.length > 24 ? player.trackTitle.slice(0, 24) + "…" : player.trackTitle
            }
            readonly property string musicId:
                player ? ((player.identity || "") + " " + (player.desktopEntry || "")).toLowerCase() : ""
            readonly property string musicIcon:
                musicId.indexOf("spotify") >= 0 ? "\uf1bc"
                : musicId.indexOf("firefox") >= 0 ? "\uf269"
                : (musicId.indexOf("chrom") >= 0 || musicId.indexOf("brave") >= 0) ? "\uf268"
                : "\uf001"
            readonly property string musicIconColor:
                musicId.indexOf("spotify") >= 0 ? "#1db954"
                : musicId.indexOf("firefox") >= 0 ? "#ff7139"
                : "" + Colors.text
            readonly property var activeTl: Hyprland.activeToplevel
            readonly property bool wsEmpty: !Hyprland.focusedWorkspace
                || !Hyprland.focusedWorkspace.toplevels
                || Hyprland.focusedWorkspace.toplevels.values.length === 0
            readonly property string winClass: {
                if (wsEmpty || !activeTl) return ""
                if (activeTl.lastIpcObject && activeTl.lastIpcObject.class) return activeTl.lastIpcObject.class
                if (activeTl.wayland && activeTl.wayland.appId) return activeTl.wayland.appId
                return ""
            }
            readonly property string winTitle: {
                if (wsEmpty || !activeTl) return "Desktop"
                const raw = winClass
                const c = raw.toLowerCase()
                const lt = (activeTl.title || "").toLowerCase()
                if (c === "" || c.indexOf("kitty") >= 0) {
                    if (lt.indexOf("nvim") >= 0 || lt.indexOf("neovim") >= 0) return "Neovim"
                    if (lt.indexOf("yazi") >= 0) return "Yazi"
                    if (c.indexOf("kitty") >= 0) return "Kitty"
                }
                if (c === "") {
                    const t = activeTl.title || "Desktop"
                    return t.length > 30 ? t.slice(0, 30) + "…" : t
                }
                const known = {
                    "firefox": "Firefox", "steam": "Steam", "discord": "Discord",
                    "spotify": "Spotify", "chromium": "Chromium", "google-chrome": "Chrome",
                    "brave": "Brave", "code": "VS Code", "obs": "OBS", "vlc": "VLC",
                    "thunar": "Thunar", "nautilus": "Arquivos", "virtualbox": "VirtualBox"
                }
                for (const k in known)
                    if (c.indexOf(k) >= 0) return known[k]
                const seg = raw.split(".").pop() || raw
                return seg.charAt(0).toUpperCase() + seg.slice(1)
            }
            function iconFor(cls, title) {
                const c = (cls || "").toLowerCase()
                const t = (title || "").toLowerCase()
                if (t === "neovim") return "\ue6ae"
                if (t === "yazi") return "\uf07b"
                if (t === "kitty") return "\uf120"
                if (c.indexOf("kitty") >= 0 || c.indexOf("foot") >= 0 || c.indexOf("alacritty") >= 0) {
                    if (t.indexOf("nvim") >= 0 || t.indexOf("neovim") >= 0) return "\ue6ae"
                    if (t.indexOf("yazi") >= 0) return "\uf07b"
                    return "\uf120"
                }
                if (c.indexOf("firefox") >= 0) return "\uf269"
                if (c.indexOf("chrom") >= 0 || c.indexOf("brave") >= 0) return "\uf268"
                if (c.indexOf("discord") >= 0) return "\uf392"
                if (c.indexOf("spotify") >= 0) return "\uf1bc"
                if (c.indexOf("steam") >= 0) return "\uf1b6"
                return "\uf2d0"
            }
            readonly property string winIcon: wsEmpty ? "\uf17c" : iconFor(winClass, winTitle)

            // ---- workspaces ----
            readonly property int focusedWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
            readonly property var kanji: ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
            readonly property var wsIcons: ["", "\uf120", "\uf269", "\uf07b", "\uf086", "\uf1b6"]
            readonly property var romans: ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]
            function wsLabel(id) {
                const st = Settings.wsStyle
                if (st === "numbers") return String(id)
                if (st === "roman") return romans[id] || String(id)
                if (st === "diamond") return id === focusedWs ? "◆" : "◇"
                if (st === "ball") return id === focusedWs ? "●" : "○"
                if (st === "icons") return id <= 5 ? wsIcons[id] : "\uf10c"
                return kanji[id] || String(id)
            }
            property var extraWs: []
            function syncExtra() {
                const e = []
                const vals = Hyprland.workspaces.values
                for (let i = 0; i < vals.length; i++) {
                    const w = vals[i]
                    const n = w.toplevels ? w.toplevels.values.length : 0
                    if (w.id > 5 && (n > 0 || w.id === focusedWs)) e.push(w.id)
                }
                if (focusedWs > 5 && e.indexOf(focusedWs) < 0) e.push(focusedWs)
                e.sort((a, c) => a - c)
                if (e.join(",") !== extraWs.join(",")) extraWs = e
            }
            Timer { interval: 250; running: true; repeat: true; triggeredOnStart: true; onTriggered: win.syncExtra() }
            readonly property var wsList: [1, 2, 3, 4, 5].concat(extraWs)

            readonly property color accentSoft: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, Settings.moduleOpacity / 100)
            readonly property color textFaded: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.45)

            // ---- slot de modulo: aparece so se a opcao do painel bater com o grupo ----
            component Mod: Loader {
                id: mod
                property string group: "start"
                property string setting: "off"
                property Component comp
                active: setting === group
                visible: active
                sourceComponent: comp
                Binding {
                    target: mod.item
                    property: "radius"
                    value: Settings.moduleRadius
                    when: mod.item !== null && mod.item.radius !== undefined
                }
            }

            // ---- modulos (versao horizontal e vertical) ----
            Component {
                id: cpuramH
                Chip {
                    hpad: 10
                    segments: [
                        { t: "\uf2db", a: true }, { t: win.cpu + "%" }, { t: "  " },
                        { t: "\uDB80\uDF5B", a: true }, { t: win.ramPct + "%" }
                    ]
                    onClicked: win.ipc("sys")
                }
            }
            Component {
                id: cpuramV
                Column {
                    spacing: 8
                    VChip {
                        segments: [{ t: "\uf2db", a: true, s: 18 }, { t: win.cpu + "%" }]
                        onClicked: win.ipc("sys")
                    }
                    VChip {
                        segments: [{ t: "\uDB80\uDF5B", a: true, s: 18 }, { t: win.ramPct + "%" }]
                        onClicked: win.ipc("sys")
                    }
                }
            }
            Component {
                id: winH
                Chip {
                    hpad: 10
                    segments: [{ t: win.winIcon, s: 18 }, { t: Settings.mini ? win.cut(win.winTitle, 16) : win.winTitle }]
                    onClicked: win.ipc("windows")
                }
            }
            Component {
                id: winV
                VText {
                    segments: [{ t: win.winIcon, s: 16 }, { t: win.cut(win.winTitle, Settings.mini ? 9 : 12) }]
                    onClicked: win.ipc("windows")
                }
            }
            Component {
                id: volH
                Chip {
                    dim: win.muted
                    segments: [{ t: win.muted ? "\uf6a9" : "\uf028" }, { t: win.vol + "%" }]
                    onClicked: win.ipc("volume")
                    onScrolled: dy => win.scrollVolume(dy)
                }
            }
            Component {
                id: volV
                VChip {
                    dim: win.muted
                    segments: [{ t: win.muted ? "\uf6a9" : "\uf028", s: 18 }, { t: win.vol + "%" }]
                    onClicked: win.ipc("volume")
                    onScrolled: dy => win.scrollVolume(dy)
                }
            }

            // ---- delegados compartilhados ----
            Component {
                id: wsDelegate
                Text {
                    required property int modelData
                    width: Settings.mini ? 28 : 36
                    horizontalAlignment: Text.AlignHCenter
                    text: win.wsLabel(modelData)
                    font.family: Settings.fontFamily
                    font.pixelSize: Math.round(((Settings.wsStyle === "kanji" || Settings.wsStyle === "numbers") ? 20 : 17) * Settings.fontScale * Settings.bs * (Settings.mini ? 0.82 : 1))
                    color: win.focusedWs === modelData || wsMa.containsMouse ? Colors.text : win.textFaded
                    Behavior on color { ColorAnimation { duration: Math.round(200 * Settings.animMul) } }
                    MouseArea {
                        id: wsMa
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                if (modelData > 5 && modelData !== win.focusedWs)
                                    win.extraWs = win.extraWs.filter(x => x !== modelData)
                                return
                            }
                            wsProc.command = ["hyprctl", "dispatch", "hl.dsp.focus({ workspace = " + modelData + " })"]
                            wsProc.running = true
                        }
                    }
                }
            }

            Component {
                id: trayDelegate
                Image {
                    required property var modelData
                    width: Settings.trayIcon
                    height: Settings.trayIcon
                    source: modelData.icon
                    sourceSize.width: Settings.trayIcon
                    sourceSize.height: Settings.trayIcon
                    fillMode: Image.PreserveAspectFit
                    TrayMenu {
                        id: trayMenu
                        handle: modelData.menu
                        parentWin: win
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            const openMenu = () => {
                                if (!modelData.hasMenu) return
                                const p = parent.mapToItem(null, 0, 0)
                                trayMenu.px = p.x; trayMenu.py = p.y
                                trayMenu.open()
                            }
                            if (mouse.button === Qt.RightButton) openMenu()
                            else if (mouse.button === Qt.MiddleButton) modelData.secondaryActivate()
                            else if (modelData.onlyMenu) openMenu()
                            else modelData.activate()
                        }
                    }
                }
            }

            // ---- hora de 12h na mao (o formato "hh" sozinho e 24h) ----
            function h12() { const h = clock.date.getHours(); return String(((h + 11) % 12) + 1).padStart(2, "0") }
            function ap() { return clock.date.getHours() < 12 ? "AM" : "PM" }

            // ---- modulos moveis ----
            Component { id: logoH; LogoChip { onClicked: win.ipc("logo") } }
            Component { id: logoV; LogoChip { vertical: true; onClicked: win.ipc("logo") } }

            Component {
                id: wsH
                Rectangle {
                    height: Settings.chipH
                    radius: Settings.moduleRadius
                    color: win.accentSoft
                    width: wsRow.implicitWidth + 12
                    Row {
                        id: wsRow
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater { model: win.wsList; delegate: wsDelegate }
                    }
                }
            }
            Component {
                id: wsV
                Rectangle {
                    width: Settings.chipH
                    height: wsCol.implicitHeight + 12
                    radius: Settings.moduleRadius
                    color: win.accentSoft
                    Column {
                        id: wsCol
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater { model: win.wsList; delegate: wsDelegate }
                    }
                }
            }

            Component {
                id: musicH
                Chip {
                    hpad: 14
                    dim: !win.playing
                    segments: win.player ? [{ t: win.musicIcon, c: win.musicIconColor, s: 16 }, { t: win.playing ? "\uf04b" : "\uf04c", s: 14 }, { t: win.musicTitle, s: 14 }] : [{ t: "\uf001", s: 14 }, { t: "Nada tocando", s: 14 }]
                    onClicked: win.ipc("music")
                    onRightClicked: if (win.player) win.player.togglePlaying()
                }
            }
            Component {
                id: musicV
                VText {
                    dim: !win.playing
                    segments: win.player ? [{ t: win.musicIcon, c: win.musicIconColor, s: 15 }, { t: win.playing ? "\uf04b" : "\uf04c", s: 12 }, { t: win.cut(win.musicTitle, 14) }] : [{ t: "\uf001", s: 14 }, { t: "Nada tocando" }]
                    onClicked: win.ipc("music")
                    onRightClicked: if (win.player) win.player.togglePlaying()
                }
            }

            Component {
                id: clockH
                Chip {
                    hpad: 12
                    segments: [{ t: Qt.formatDateTime(clock.date, Settings.clock24h ? "HH:mm" : "hh:mm AP") }]
                    extra: " > " + Qt.formatDateTime(clock.date, "dd/MM/yyyy")
                    onClicked: win.ipc("calendar")
                }
            }
            Component {
                id: clockV
                VChip {
                    segments: [
                        { t: Settings.clock24h ? Qt.formatDateTime(clock.date, "HH") : win.h12(), s: 15 },
                        { t: Qt.formatDateTime(clock.date, "mm"), s: 15 }
                    ].concat(Settings.clock24h ? [] : [{ t: win.ap(), s: 10 }])
                    onClicked: win.ipc("calendar")
                }
            }

            Component {
                id: powerH
                Chip {
                    hpad: 14
                    segments: [{ t: "\uf011", c: "#ff6b9d", s: 16 }]
                    onClicked: win.ipc("power")
                }
            }
            Component {
                id: powerV
                VChip {
                    segments: [{ t: "\uf011", c: "#ff6b9d", s: 16 }]
                    onClicked: win.ipc("power")
                }
            }

            // ================= FUNDO DA BARRA =================
            Rectangle {
                anchors.fill: parent
                radius: Settings.barStyle === "docked" ? 0 : Settings.barRadius
                color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.barOpacity)
                border.width: 2
                border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10 * Settings.barOpacity)

                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) { sc.shown = true; hideT.stop() }
                        else hideT.restart()
                    }
                }

                // =====================================================
                //  LAYOUT HORIZONTAL (topo / embaixo)
                // =====================================================
                Item {
                    anchors.fill: parent
                    visible: !win.vert

                    // ---------- INICIO ----------
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Mod { group: "start"; setting: Settings.logoPlace; comp: logoH }
                        Mod { group: "start"; setting: Settings.cpuRamPlace; comp: cpuramH }
                        Mod { group: "start"; setting: Settings.windowPlace; comp: winH }
                        Mod { group: "start"; setting: Settings.wsPlace; comp: wsH }
                        Mod { group: "start"; setting: Settings.musicPlace; comp: musicH }
                        Mod { group: "start"; setting: Settings.volumePlace; comp: volH }
                        Mod { group: "start"; setting: Settings.clockPlace; comp: clockH }
                        Mod { group: "start"; setting: Settings.powerPlace; comp: powerH }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "|"
                            color: Colors.text
                            font.family: Settings.fontFamily
                            font.pixelSize: 12
                        }
                    }

                    // ---------- CENTRO ----------
                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Mod { group: "center"; setting: Settings.logoPlace; comp: logoH }
                        Mod { group: "center"; setting: Settings.cpuRamPlace; comp: cpuramH }
                        Mod { group: "center"; setting: Settings.windowPlace; comp: winH }
                        Mod { group: "center"; setting: Settings.wsPlace; comp: wsH }
                        Mod { group: "center"; setting: Settings.musicPlace; comp: musicH }
                        Mod { group: "center"; setting: Settings.volumePlace; comp: volH }
                        Mod { group: "center"; setting: Settings.clockPlace; comp: clockH }
                        Mod { group: "center"; setting: Settings.powerPlace; comp: powerH }
                    }

                    // ---------- FIM ----------
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Mod { group: "end"; setting: Settings.logoPlace; comp: logoH }
                        Mod { group: "end"; setting: Settings.cpuRamPlace; comp: cpuramH }
                        Mod { group: "end"; setting: Settings.windowPlace; comp: winH }
                        Mod { group: "end"; setting: Settings.wsPlace; comp: wsH }
                        Mod { group: "end"; setting: Settings.musicPlace; comp: musicH }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "|"
                            color: Colors.text
                            font.family: Settings.fontFamily
                            font.pixelSize: 12
                        }

                        Rectangle { // NOVO-TRAY
                            visible: Settings.netOn || SystemTray.items.values.length > 0
                            height: Settings.chipH
                            radius: Settings.moduleRadius
                            color: win.accentSoft
                            width: trayRow.implicitWidth + (Settings.mini ? 14 : 20)
                            Row {
                                id: trayRow
                                anchors.centerIn: parent
                                spacing: Settings.mini ? 6 : 8
                                Text { // NET-IN-TRAY
                                    visible: Settings.netOn
                                    width: Settings.trayIcon + 2
                                    height: Settings.trayIcon + 2
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: win.netIcon
                                    font.family: Settings.fontFamily
                                    font.pixelSize: Settings.trayIcon
                                    color: win.netUp ? Colors.text : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.4)
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.ipc("network")
                                    }
                                }
                                Repeater { model: SystemTray.items.values; delegate: trayDelegate }
                            }
                        }

                        Mod { group: "end"; setting: Settings.volumePlace; comp: volH }
                        Mod { group: "end"; setting: Settings.clockPlace; comp: clockH }
                        Mod { group: "end"; setting: Settings.powerPlace; comp: powerH }
                    }
                }

                // =====================================================
                //  LAYOUT VERTICAL (esquerda / direita)
                // =====================================================
                Item {
                    anchors.fill: parent
                    visible: win.vert

                    // ---------- INICIO (cima) ----------
                    Column {
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Mod { group: "start"; setting: Settings.logoPlace; comp: logoV }
                        Mod { group: "start"; setting: Settings.cpuRamPlace; comp: cpuramV }
                        Mod { group: "start"; setting: Settings.windowPlace; comp: winV }
                        Mod { group: "start"; setting: Settings.wsPlace; comp: wsV }
                        Mod { group: "start"; setting: Settings.musicPlace; comp: musicV }
                        Mod { group: "start"; setting: Settings.volumePlace; comp: volV }
                        Mod { group: "start"; setting: Settings.clockPlace; comp: clockV }
                        Mod { group: "start"; setting: Settings.powerPlace; comp: powerV }
                    }

                    // ---------- CENTRO ----------
                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Mod { group: "center"; setting: Settings.logoPlace; comp: logoV }
                        Mod { group: "center"; setting: Settings.cpuRamPlace; comp: cpuramV }
                        Mod { group: "center"; setting: Settings.windowPlace; comp: winV }
                        Mod { group: "center"; setting: Settings.wsPlace; comp: wsV }
                        Mod { group: "center"; setting: Settings.musicPlace; comp: musicV }
                        Mod { group: "center"; setting: Settings.volumePlace; comp: volV }
                        Mod { group: "center"; setting: Settings.clockPlace; comp: clockV }
                        Mod { group: "center"; setting: Settings.powerPlace; comp: powerV }
                    }

                    // ---------- FIM (baixo) ----------
                    Column {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Mod { group: "end"; setting: Settings.logoPlace; comp: logoV }
                        Mod { group: "end"; setting: Settings.cpuRamPlace; comp: cpuramV }
                        Mod { group: "end"; setting: Settings.windowPlace; comp: winV }
                        Mod { group: "end"; setting: Settings.wsPlace; comp: wsV }
                        Mod { group: "end"; setting: Settings.musicPlace; comp: musicV }

                        Rectangle { // NOVO-TRAY
                            visible: Settings.netOn || SystemTray.items.values.length > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Settings.chipH
                            radius: Settings.moduleRadius
                            color: win.accentSoft
                            height: trayCol.implicitHeight + (Settings.mini ? 12 : 16)
                            Column {
                                id: trayCol
                                anchors.centerIn: parent
                                spacing: Settings.mini ? 6 : 8
                                Text { // NET-IN-TRAY
                                    visible: Settings.netOn
                                    width: Settings.trayIcon + 2
                                    height: Settings.trayIcon + 2
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: win.netIcon
                                    font.family: Settings.fontFamily
                                    font.pixelSize: Settings.trayIcon
                                    color: win.netUp ? Colors.text : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.4)
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.ipc("network")
                                    }
                                }
                                Repeater { model: SystemTray.items.values; delegate: trayDelegate }
                            }
                        }

                        Mod { group: "end"; setting: Settings.volumePlace; comp: volV }
                        Mod { group: "end"; setting: Settings.clockPlace; comp: clockV }
                        Mod { group: "end"; setting: Settings.powerPlace; comp: powerV }
                    }
                }
            }
        }
    }
}
