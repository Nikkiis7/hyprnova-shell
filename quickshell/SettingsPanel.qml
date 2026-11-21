import QtQuick
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: win
    visible: false
    title: "Configurações"
    color: Colors.card
    implicitWidth: 820
    implicitHeight: 560
    minimumSize: Qt.size(820, 560)
    maximumSize: Qt.size(820, 560)

    property int tab: 0
    readonly property var placeOpts: [{ v: "start", t: Tr.t("Início") }, { v: "center", t: Tr.t("Centro") }, { v: "end", t: Tr.t("Fim") }, { v: "off", t: Tr.t("Oculto") }]
    readonly property var placeOpts3: [{ v: "start", t: Tr.t("Início") }, { v: "center", t: Tr.t("Centro") }, { v: "end", t: Tr.t("Fim") }]

    IpcHandler {
        target: "settings"
        function toggle(): void { win.visible = !win.visible }
        function show(): void { win.visible = true }
    }

    Shortcut { sequence: "Escape"; onActivated: win.visible = false }

    Process { id: notif }

    Process { id: hyprProc }
    function applyHypr() { applyT.restart() }
    Process { id: kittyProc }
    Timer {
        id: kittyT
        interval: 250
        onTriggered: {
            kittyProc.command = [Quickshell.env("HOME") + "/.local/bin/kitty-opacity", String((100 - Settings.kittyTransp) / 100)]
            kittyProc.running = true
        }
    }
    Timer {
        id: applyT
        interval: 300
        onTriggered: {
            hyprProc.command = [Quickshell.env("HOME") + "/.local/bin/hypr-appearance",
                "blur=" + Settings.blurOn, "anim=" + Settings.animMode,
                "winBlur=" + Settings.hWinBlur, "animOn=" + Settings.hAnimOn,
                "layout=" + Settings.hLayout, "border=" + Settings.hBorder, "rounding=" + Settings.hRound,
                "gapsIn=" + Settings.hGapsIn, "gapsOut=" + Settings.hGapsOut,
                "single=" + Settings.hSingle, "hideInactive=" + Settings.hHideInactive]
            hyprProc.running = true
        }
    }

    property var fontList: []
    readonly property var dockNames: ({ top: "em cima", bottom: "embaixo", left: "à esquerda", right: "à direita" })
    Process {
        id: fcProc
        running: true
        command: ["sh", "-c", "fc-list : family | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = {}
                const lines = text.split("\n")
                for (let i = 0; i < lines.length; i++) {
                    const parts = lines[i].split(",")
                    for (let j = 0; j < parts.length; j++) {
                        const f = parts[j].trim()
                        if (f !== "" && f.charAt(0) !== ".") set[f] = true
                    }
                }
                win.fontList = Object.keys(set).sort()
            }
        }
    }
    function notify(title, body) {
        notif.command = ["notify-send", "-a", "Configurações", "-t", "3000", title, body]
        notif.running = true
    }
    readonly property var posNames: ({ top: "no topo", bottom: "embaixo", left: "à esquerda", right: "à direita" })

    Process {
        id: openColors
        command: ["quickshell", "ipc", "call", "wallcolors", "show"]
    }

    // ---------- componentes ----------
    component SRow: Item {
        id: r
        property string label: ""
        property string hint: ""
        property string def: ""
        property bool stacked: false
        default property alias content: slot.data
        readonly property color dimText: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.55)
        width: parent ? parent.width : 0
        height: stacked ? 104 : 66

        Column {
            anchors.top: r.stacked ? parent.top : undefined
            anchors.topMargin: 10
            anchors.verticalCenter: r.stacked ? undefined : parent.verticalCenter
            spacing: 2
            Text {
                width: Math.max(0, r.stacked ? r.width : r.width - slot.width - 24)
                elide: Text.ElideRight
                text: r.label
                color: Colors.text
                font.pixelSize: 15
            }
            Text {
                visible: r.hint !== ""
                width: Math.max(0, r.stacked ? r.width : r.width - slot.width - 24)
                elide: Text.ElideRight
                text: r.hint
                color: r.dimText
                font.pixelSize: 12
            }
            Text {
                visible: r.def !== ""
                width: Math.max(0, r.stacked ? r.width : r.width - slot.width - 24)
                elide: Text.ElideRight
                text: Tr.t("padrão: ") + r.def
                color: r.dimText
                font.pixelSize: 11
            }
        }
        Item {
            id: slot
            anchors.right: r.stacked ? undefined : parent.right
            anchors.left: r.stacked ? parent.left : undefined
            anchors.verticalCenter: r.stacked ? undefined : parent.verticalCenter
            anchors.bottom: r.stacked ? parent.bottom : undefined
            anchors.bottomMargin: 12
            width: childrenRect.width
            height: childrenRect.height
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Colors.border
            opacity: 0.5
        }
    }

    component Toggle: Rectangle {
        id: t
        property bool on: false
        signal toggled()
        width: 46; height: 26; radius: 13
        color: on ? Colors.accent : Colors.surface
        Behavior on color { ColorAnimation { duration: Math.round(120 * Settings.animMul) } }
        Rectangle {
            width: 20; height: 20; radius: 10
            y: 3
            x: t.on ? parent.width - width - 3 : 3
            color: t.on ? Colors.onAccent : Colors.text
            Behavior on x { NumberAnimation { duration: Math.round(120 * Settings.animMul) } }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: t.toggled() }
    }

    component Seg: Row {
        id: sg
        property var options: []
        property var current
        signal picked(var v)
        spacing: 4
        Repeater {
            model: sg.options
            Rectangle {
                required property var modelData
                readonly property bool sel: sg.current === modelData.v
                height: 30
                width: lbl.implicitWidth + 24
                radius: 6
                color: sel ? Colors.accent : Colors.surface
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: modelData.t
                    font.pixelSize: 13
                    color: parent.sel ? Colors.onAccent : Colors.text
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sg.picked(modelData.v) }
            }
        }
    }

    component Sld: Item {
        id: s
        property real from: 0
        property real to: 1
        property real value: 0
        property real step: 1
        property string valueText: String(Math.round(value))
        signal moved(real v)
        width: 280; height: 26
        readonly property real frac: (value - from) / (to - from)

        Rectangle {
            id: tr
            anchors.verticalCenter: parent.verticalCenter
            width: s.width - 56; height: 6; radius: 3
            color: Colors.surface
            Rectangle { width: parent.width * s.frac; height: parent.height; radius: 3; color: Colors.accent }
            Rectangle {
                x: parent.width * s.frac - 8; y: -5
                width: 16; height: 16; radius: 8
                color: Colors.accent
            }
        }
        MouseArea {
            width: tr.width; height: s.height
            cursorShape: Qt.PointingHandCursor
            function setv(mx) {
                var f = Math.max(0, Math.min(1, mx / width))
                var v = s.from + f * (s.to - s.from)
                v = s.from + Math.round((v - s.from) / s.step) * s.step
                s.moved(Number(v.toFixed(3)))
            }
            onPressed: mouse => setv(mouse.x)
            onPositionChanged: mouse => { if (pressed) setv(mouse.x) }
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: s.valueText
            color: Colors.text
            font.pixelSize: 13
        }
    }

    component Btn: Rectangle {
        id: b
        property string text: ""
        signal clicked()
        height: 32; width: bt.implicitWidth + 28; radius: 6
        color: ma.containsMouse ? Colors.accent : Colors.surface
        Text {
            id: bt
            anchors.centerIn: parent
            text: b.text
            font.pixelSize: 13
            color: ma.containsMouse ? Colors.onAccent : Colors.text
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
    }

    component SHead: Item {
        property string label: ""
        width: parent ? parent.width : 0
        height: 46
        Text {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: parent.label
            color: Colors.accent
            font.pixelSize: 13
            font.bold: true
        }
    }

    // ---------- layout ----------
    Row {
        anchors.fill: parent

        // Barra lateral
        Rectangle {
            width: 200; height: parent.height
            color: Colors.surface

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                Text {
                    text: Tr.t("Configurações")
                    color: Colors.text
                    font.pixelSize: 18
                    font.bold: true
                    bottomPadding: 12
                }

                Repeater {
                    model: ["Aparência", "Barra", "Notificações", "Hyprland", "Binds", "Widgets", "Fastfetch", "Sobre"]
                    Rectangle {
                        required property string modelData
                        required property int index
                        width: parent.width; height: 40; radius: 8
                        color: win.tab === index ? Colors.accent : (hv.containsMouse ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.15) : "transparent")
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 14
                            text: Tr.t(modelData)
                            font.pixelSize: 15
                            color: win.tab === index ? Colors.onAccent : Colors.text
                        }
                        MouseArea { id: hv; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.tab = index }
                    }
                }
            }
        }

        // Conteúdo
        Item {
            width: parent.width - 200; height: parent.height

            // ---- Aparência ----
            Flickable {
                anchors.fill: parent; anchors.margins: 28
                visible: win.tab === 0
                clip: true
                contentHeight: c0.height
                Column {
                    id: c0
                    width: parent.width

                    SRow {
                        label: Tr.t("Tema")
                        def: Tr.t("Escuro")
                        Seg {
                            options: [{ v: "dark", t: Tr.t("Escuro") }, { v: "light", t: Tr.t("Claro") }]
                            current: Settings.themeMode
                            onPicked: v => { Settings.themeMode = v; win.notify("Tema alterado", v === "light" ? "Tema claro ativado" : "Tema escuro ativado") }
                        }
                    }

                    SRow {
                        label: Tr.t("Animações")
                        hint: Tr.t("Simples = só fade rápido (Hyprland e painéis)")
                        def: Tr.t("Complexas")
                        Seg {
                            options: [{ v: "simple", t: Tr.t("Simples") }, { v: "complex", t: Tr.t("Complexas") }]
                            current: Settings.animMode
                            onPicked: v => { Settings.animMode = v; win.applyHypr() }
                        }
                    }
                    SRow {
                        label: Tr.t("Blur dos widgets")
                        hint: Tr.t("Desfoque atrás das janelas (Hyprland)")
                        def: Tr.t("Ativado")
                        Seg {
                            options: [{ v: true, t: Tr.t("Ativado") }, { v: false, t: Tr.t("Desativado") }]
                            current: Settings.blurOn
                            onPicked: v => { Settings.blurOn = v; win.applyHypr() }
                        }
                    }

                    SRow {
                        label: Tr.t("Transparência")
                        hint: Tr.t("Fundo dos painéis, notificações e Dock")
                        def: Tr.t("88 %")
                        Sld { from: 0; to: 100; step: 1; value: Math.round(Settings.uiOpacity * 100); valueText: Math.round(value) + " %"; onMoved: v => Settings.uiOpacity = v / 100 }
                    }

                    SHead { label: Tr.t("TEXTO") }
                    SRow {
                        label: Tr.t("Fonte")
                        hint: Tr.t("Fontes sem ícones usam a Nerd Font como reserva para os símbolos")
                        def: Tr.t("Iosevka")
                        Seg {
                            options: [{ v: "default", t: Tr.t("Iosevka") }, { v: "other", t: Tr.t("Outras fontes") }]
                            current: Settings.fontMode
                            onPicked: v => Settings.fontMode = v
                        }
                    }
                    Item {
                        id: fontBox
                        visible: Settings.fontMode === "other"
                        property string q: ""
                        width: parent.width
                        height: visible ? 290 : 0
                        Rectangle {
                            id: fsearch
                            y: 4
                            width: parent.width
                            height: 32
                            radius: 6
                            color: Colors.surface
                            TextInput {
                                id: fin
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.text
                                font.pixelSize: 13
                                clip: true
                                onTextChanged: fontBox.q = text.toLowerCase()
                            }
                            Text {
                                anchors.fill: fin
                                verticalAlignment: Text.AlignVCenter
                                visible: fin.text === ""
                                text: "Buscar entre " + win.fontList.length + " fontes instaladas..."
                                color: Colors.text
                                opacity: 0.5
                                font.pixelSize: 13
                            }
                        }
                        ListView {
                            y: 44
                            width: parent.width
                            height: parent.height - 48
                            clip: true
                            spacing: 4
                            boundsBehavior: Flickable.StopAtBounds
                            model: win.fontList.filter(f => f.toLowerCase().indexOf(fontBox.q) >= 0)
                            delegate: Rectangle {
                                required property string modelData
                                readonly property bool sel: Settings.fontChoice === modelData
                                width: ListView.view.width
                                height: 32
                                radius: 6
                                color: sel ? Colors.accent : Colors.surface
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: 12
                                    text: modelData
                                    font.family: modelData
                                    font.pixelSize: 15
                                    color: parent.sel ? Colors.onAccent : Colors.text
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.fontChoice = modelData
                                }
                            }
                        }
                    }
                    SRow {
                        label: Tr.t("Tamanho da fonte")
                        hint: Tr.t("Vale para a barra, o relógio de fundo e a dock")
                        def: Tr.t("Média")
                        Seg {
                            options: [{ v: "small", t: Tr.t("Pequena") }, { v: "medium", t: Tr.t("Média") }, { v: "large", t: Tr.t("Grande") }]
                            current: Settings.fontSizeMode
                            onPicked: v => Settings.fontSizeMode = v
                        }
                    }

                    SHead { label: Tr.t("DOCK") }
                    SRow {
                        label: Tr.t("Exibir Dock")
                        hint: Tr.t("Esquerda: abre/foca · meio: nova janela · direita: fixar")
                        def: Tr.t("Ocultar")
                        Seg {
                            options: [{ v: true, t: Tr.t("Exibir") }, { v: false, t: Tr.t("Ocultar") }]
                            current: Settings.dockShow
                            onPicked: v => Settings.dockShow = v
                        }
                    }
                    SRow {
                        label: Tr.t("› Posição")
                        def: Tr.t("Baixo")
                        Seg {
                            options: [{ v: "bottom", t: Tr.t("Baixo") }, { v: "top", t: Tr.t("Cima") }, { v: "left", t: Tr.t("Esquerda") }, { v: "right", t: Tr.t("Direita") }]
                            current: Settings.dockPosition
                            onPicked: v => { Settings.dockPosition = v; win.notify("Posição da Dock alterada", "Dock " + win.dockNames[v]) }
                        }
                    }
                    SRow {
                        label: Tr.t("› Exibir ao passar o mouse")
                        hint: Tr.t("Some e volta quando o mouse encosta na borda")
                        def: Tr.t("Desligado")
                        Seg {
                            options: [{ v: true, t: Tr.t("Ligado") }, { v: false, t: Tr.t("Desligado") }]
                            current: Settings.dockAutoHide
                            onPicked: v => Settings.dockAutoHide = v
                        }
                    }
                }
            }

            // ---- Barra ----
            Flickable {
                anchors.fill: parent; anchors.margins: 28
                visible: win.tab === 1
                clip: true
                contentHeight: c1.height
                Column {
                    id: c1
                    width: parent.width

                    SRow {
                        label: Tr.t("Posição da barra")
                        def: Tr.t("Topo")
                        Seg {
                            options: [{ v: "top", t: Tr.t("Topo") }, { v: "bottom", t: Tr.t("Embaixo") }, { v: "left", t: Tr.t("Esquerda") }, { v: "right", t: Tr.t("Direita") }]
                            current: Settings.barPosition
                            onPicked: v => { Settings.barPosition = v; win.notify("Posição da barra alterada", "Barra " + win.posNames[v]) }
                        }
                    }
                    SRow {
                        label: Tr.t("Estilo")
                        hint: Tr.t("Flutuante tem margem; colada encosta na borda da tela")
                        def: Tr.t("Flutuante")
                        Seg {
                            options: [{ v: "floating", t: Tr.t("Flutuante") }, { v: "docked", t: Tr.t("Colada") }]
                            current: Settings.barStyle
                            onPicked: v => Settings.barStyle = v
                        }
                    }
                    SRow {
                        label: Tr.t("Ocultar barra sozinha")
                        hint: Tr.t("Ela volta quando o mouse encosta na borda da tela")
                        def: Tr.t("Desligado")
                        Seg {
                            options: [{ v: true, t: Tr.t("Ligado") }, { v: false, t: Tr.t("Desligado") }]
                            current: Settings.autoHide
                            onPicked: v => Settings.autoHide = v
                        }
                    }

                    SRow {
                        label: Tr.t("Tamanho da barra")
                        hint: Tr.t("Mínima: barra mais fina, módulos compactos e sem o título da janela")
                        def: Tr.t("Padrão")
                        Seg {
                            options: [{ v: "minimal", t: Tr.t("Mínima") }, { v: "default", t: Tr.t("Padrão") }]
                            current: Settings.barSize
                            onPicked: v => Settings.barSize = v
                        }
                    }

                    SHead { label: Tr.t("MÓDULOS  ·  Início = esquerda/topo  ·  Fim = direita/baixo") }
                    SRow { label: Tr.t("Posição da logo"); def: Tr.t("Início"); Seg { options: win.placeOpts; current: Settings.logoPlace; onPicked: v => Settings.logoPlace = v } }
                    SRow { label: Tr.t("Posição da CPU e da RAM"); def: Tr.t("Início"); Seg { options: win.placeOpts; current: Settings.cpuRamPlace; onPicked: v => Settings.cpuRamPlace = v } }
                    SRow { label: Tr.t("Posição da janela"); def: Tr.t("Início"); Seg { options: win.placeOpts; current: Settings.windowPlace; onPicked: v => Settings.windowPlace = v } }
                    SRow { label: Tr.t("Posição da workspace"); def: Tr.t("Centro"); Seg { options: win.placeOpts; current: Settings.wsPlace; onPicked: v => Settings.wsPlace = v } }
                    SRow { label: Tr.t("Posição do player"); def: Tr.t("Fim"); Seg { options: win.placeOpts; current: Settings.musicPlace; onPicked: v => Settings.musicPlace = v } }
                    SRow { label: Tr.t("Posição do volume"); def: Tr.t("Fim"); Seg { options: win.placeOpts; current: Settings.volumePlace; onPicked: v => Settings.volumePlace = v } }
                    SRow { label: Tr.t("Posição do relógio"); def: Tr.t("Fim"); Seg { options: win.placeOpts; current: Settings.clockPlace; onPicked: v => Settings.clockPlace = v } }
                    SRow { label: Tr.t("Posição do ícone de desligar"); def: Tr.t("Fim"); Seg { options: win.placeOpts; current: Settings.powerPlace; onPicked: v => Settings.powerPlace = v } }

                    SHead { label: Tr.t("VISUAL") }
                    SRow {
                        label: Tr.t("Opacidade da barra")
                        def: Tr.t("88 %")
                        Sld { from: 0; to: 100; step: 1; value: Math.round(Settings.barOpacity * 100); valueText: Math.round(value) + " %"; onMoved: v => Settings.barOpacity = v / 100 }
                    }
                    SRow {
                        label: Tr.t("Arredondamento da barra")
                        hint: Tr.t("Na barra colada fica sem arredondamento")
                        def: Tr.t("5 px")
                        Sld { from: 0; to: 100; step: 1; value: Settings.barRadius; valueText: Math.round(value) + " px"; onMoved: v => Settings.barRadius = v }
                    }
                    SRow {
                        label: Tr.t("Arredondamento dos módulos")
                        def: Tr.t("5 px")
                        Sld { from: 0; to: 100; step: 1; value: Settings.moduleRadius; valueText: Math.round(value) + " px"; onMoved: v => Settings.moduleRadius = v }
                    }
                    SRow {
                        label: Tr.t("Opacidade do fundo dos módulos")
                        def: Tr.t("10 %")
                        Sld { from: 0; to: 100; step: 1; value: Settings.moduleOpacity; valueText: Math.round(value) + " %"; onMoved: v => Settings.moduleOpacity = v }
                    }
                    SRow {
                        label: Tr.t("Estilo da logo")
                        def: Tr.t("Arch")
                        Seg {
                            options: [{ v: "arch", t: Tr.t("Arch") }, { v: "hyprland", t: Tr.t("Hyprland") }, { v: "hyprnova", t: Tr.t("Hyprnova") }]
                            current: Settings.logoStyle
                            onPicked: v => Settings.logoStyle = v
                        }
                    }
                    SRow {
                        label: Tr.t("Estilo da workspace")
                        def: Tr.t("Japonês")
                        stacked: true
                        Seg {
                            options: [{ v: "kanji", t: Tr.t("Japonês") }, { v: "numbers", t: Tr.t("Números") }, { v: "roman", t: Tr.t("Romanos") }, { v: "diamond", t: Tr.t("Losângulos") }, { v: "ball", t: Tr.t("Bolas") }, { v: "icons", t: Tr.t("Ícones") }]
                            current: Settings.wsStyle
                            onPicked: v => Settings.wsStyle = v
                        }
                    }
                    SRow {
                        label: Tr.t("Horário")
                        def: Tr.t("12 horas")
                        Seg {
                            options: [{ v: false, t: Tr.t("12 horas") }, { v: true, t: Tr.t("24 horas") }]
                            current: Settings.clock24h
                            onPicked: v => Settings.clock24h = v
                        }
                    }
                }
            }

            // ---- Hyprland ----
            Flickable {
                anchors.fill: parent; anchors.margins: 28
                visible: win.tab === 3
                clip: true
                contentHeight: c3.height
                Column {
                    id: c3
                    width: parent.width
                    SRow {
                        label: Tr.t("Estilo das janelas")
                        hint: Tr.t("Dwindle divide a tela em árvore · Master: uma janela grande e as outras ao lado")
                        def: Tr.t("Dwindle")
                        Seg { options: [{ v: "dwindle", t: Tr.t("Dwindle") }, { v: "master", t: Tr.t("Master") }]; current: Settings.hLayout; onPicked: v => { Settings.hLayout = v; win.applyHypr() } }
                    }
                    SRow {
                        label: Tr.t("Tamanho da borda")
                        def: Tr.t("3 px")
                        Sld { from: 0; to: 20; step: 1; value: Settings.hBorder; valueText: Math.round(value) + " px"; onMoved: v => { Settings.hBorder = Math.round(v); win.applyHypr() } }
                    }
                    SRow {
                        label: Tr.t("Arredondamento da borda")
                        def: Tr.t("1 px")
                        Sld { from: 0; to: 100; step: 1; value: Settings.hRound; valueText: Math.round(value) + " px"; onMoved: v => { Settings.hRound = Math.round(v); win.applyHypr() } }
                    }
                    SRow {
                        label: Tr.t("Transparência do kitty")
                        hint: Tr.t("Fica desfocada se o Blur das janelas estiver ligado")
                        def: Tr.t("0 %")
                        Sld { from: 0; to: 90; step: 1; value: Settings.kittyTransp; valueText: Math.round(value) + " %"; onMoved: v => { Settings.kittyTransp = Math.round(v); kittyT.restart() } }
                    }
                    SRow {
                        label: Tr.t("Espaço entre janelas")
                        hint: Tr.t("gaps_in")
                        def: Tr.t("5 px")
                        Sld { from: 0; to: 100; step: 1; value: Settings.hGapsIn; valueText: Math.round(value) + " px"; onMoved: v => { Settings.hGapsIn = Math.round(v); win.applyHypr() } }
                    }
                    SRow {
                        label: Tr.t("Espaço até a borda da tela")
                        hint: Tr.t("gaps_out")
                        def: Tr.t("10 px")
                        Sld { from: 0; to: 100; step: 1; value: Settings.hGapsOut; valueText: Math.round(value) + " px"; onMoved: v => { Settings.hGapsOut = Math.round(v); win.applyHypr() } }
                    }
                    SRow {
                        label: Tr.t("Blur das janelas")
                        hint: Tr.t("Desfoque atrás das janelas (kitty, navegador...)")
                        def: Tr.t("Ligado")
                        Seg { options: [{ v: true, t: Tr.t("Ligado") }, { v: false, t: Tr.t("Desligado") }]; current: Settings.hWinBlur; onPicked: v => { Settings.hWinBlur = v; win.applyHypr() } }
                    }
                    SRow {
                        label: Tr.t("Animações do Hyprland")
                        def: Tr.t("Ligadas")
                        Seg { options: [{ v: true, t: Tr.t("Ligadas") }, { v: false, t: Tr.t("Desligadas") }]; current: Settings.hAnimOn; onPicked: v => { Settings.hAnimOn = v; win.applyHypr() } }
                    }
                    SRow {
                        label: Tr.t("Cor da borda")
                        def: Tr.t("Gradiente")
                        Seg { options: [{ v: true, t: Tr.t("Cor única") }, { v: false, t: Tr.t("Gradiente") }]; current: Settings.hSingle; onPicked: v => { Settings.hSingle = v; win.applyHypr() } }
                    }
                    SRow {
                        label: Tr.t("Borda das janelas inativas")
                        def: Tr.t("Mostrar")
                        Seg { options: [{ v: false, t: Tr.t("Mostrar") }, { v: true, t: Tr.t("Ocultar") }]; current: Settings.hHideInactive; onPicked: v => { Settings.hHideInactive = v; win.applyHypr() } }
                    }

                    SHead { label: Tr.t("MONITOR") }
                    Column {
                        id: resBox
                        width: parent.width
                        property string mon: ""
                        property string cur: ""
                        property var res: []
                        property string selRes: ""
                        property string selHz: ""
                        function chunk(a, n) { const o = []; for (let i = 0; i < a.length; i += n) o.push(a.slice(i, i + n)); return o }
                        readonly property var hzList: {
                            const r = res.find(x => x.r === selRes)
                            return r ? r.hz : []
                        }
                        Component.onCompleted: resList.running = true
                        Process {
                            id: resList
                            command: [Quickshell.env("HOME") + "/.local/bin/hypr-res", "list"]
                            stdout: StdioCollector {
                                onStreamFinished: {
                                    const out = []
                                    text.trim().split("\n").forEach(l => {
                                        const i = l.indexOf("="); if (i < 0) return
                                        const k = l.slice(0, i), v = l.slice(i + 1)
                                        if (k === "mon") resBox.mon = v
                                        else if (k === "cur") resBox.cur = v
                                        else if (k === "mode") { const p = v.split(" "); out.push({ r: p[0], hz: p.slice(1) }) }
                                    })
                                    resBox.res = out
                                    const c = resBox.cur.split("@")
                                    resBox.selRes = c[0]
                                    const r = out.find(x => x.r === c[0])
                                    resBox.selHz = r ? (r.hz.find(h => Math.abs(parseFloat(h) - parseFloat(c[1])) < 0.02) || r.hz[0]) : ""
                                }
                            }
                        }
                        Process { id: resSet }
                        Timer { id: resReload; interval: 2500; onTriggered: resList.running = true }
                        SRow {
                            label: Tr.t("Resolução")
                            hint: resBox.mon + " · " + Tr.t("atual") + ": " + resBox.cur.replace("@", " @ ") + " Hz"
                            def: ""
                        }
                        Column {
                            spacing: 6
                            bottomPadding: 12
                            Repeater {
                                model: resBox.chunk(resBox.res.map(x => ({ v: x.r, t: x.r })), 4)
                                Seg {
                                    options: modelData
                                    current: resBox.selRes
                                    onPicked: v => {
                                        resBox.selRes = v
                                        const r = resBox.res.find(x => x.r === v)
                                        if (r && r.hz.indexOf(resBox.selHz) < 0) resBox.selHz = r.hz[0]
                                    }
                                }
                            }
                        }
                        SRow {
                            label: Tr.t("Taxa de atualização")
                            hint: ""
                            def: ""
                        }
                        Column {
                            spacing: 6
                            bottomPadding: 12
                            Repeater {
                                model: resBox.chunk(resBox.hzList.map(h => ({ v: h, t: parseFloat(h) + " Hz" })), 4)
                                Seg {
                                    options: modelData
                                    current: resBox.selHz
                                    onPicked: v => resBox.selHz = v
                                }
                            }
                        }
                        SRow {
                            label: Tr.t("Aplicar alterações")
                            hint: Tr.t("Tela preta? Use Restaurar padrão")
                            def: ""
                            Seg {
                                options: [{ v: "apply", t: Tr.t("Aplicar") }, { v: "reset", t: Tr.t("Restaurar padrão") }]
                                current: ""
                                onPicked: v => {
                                    const b = Quickshell.env("HOME") + "/.local/bin/hypr-res"
                                    resSet.command = v === "apply"
                                        ? [b, "set", resBox.mon, resBox.selRes + "@" + resBox.selHz]
                                        : [b, "reset"]
                                    resSet.running = true
                                    resReload.restart()
                                }
                            }
                        }
                    }
                }
            }

            // ---- Binds ----
            Item {
                id: bp
                anchors.fill: parent
                anchors.margins: 28
                visible: win.tab === 4

                property var list: []
                property string status: ""
                property int editing: -1
                property bool eSuper: false
                property bool eCtrl: false
                property bool eAlt: false
                property bool eShift: false
                property string eKey: ""
                readonly property string script: Quickshell.env("HOME") + "/.local/bin/hypr-binds"

                function reload() { bindList.running = true }
                function hasMod(n) { return n === "SUPER" ? eSuper : (n === "CTRL" ? eCtrl : (n === "ALT" ? eAlt : eShift)) }
                function toggleMod(n) {
                    if (n === "SUPER") eSuper = !eSuper
                    else if (n === "CTRL") eCtrl = !eCtrl
                    else if (n === "ALT") eAlt = !eAlt
                    else eShift = !eShift
                }
                function combo() {
                    const m = []
                    if (eSuper) m.push("SUPER")
                    if (eCtrl) m.push("CTRL")
                    if (eAlt) m.push("ALT")
                    if (eShift) m.push("SHIFT")
                    m.push(eKey.trim())
                    return m.join(" + ")
                }
                function startEdit(b) {
                    eSuper = b.mods.indexOf("SUPER") >= 0
                    eCtrl = b.mods.indexOf("CTRL") >= 0
                    eAlt = b.mods.indexOf("ALT") >= 0
                    eShift = b.mods.indexOf("SHIFT") >= 0
                    eKey = b.key
                    status = ""
                    editing = b.id
                }
                function save(id, c) {
                    bindSet.command = ["python3", script, "set", String(id), c]
                    bindSet.running = true
                }
                onVisibleChanged: if (visible) reload()

                Process {
                    id: bindList
                    command: ["python3", bp.script, "list"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            try { bp.list = JSON.parse(text) }
                            catch (e) { bp.status = "Não consegui ler as binds do hyprland.lua" }
                        }
                    }
                }
                Process {
                    id: bindSet
                    stdout: StdioCollector {
                        onStreamFinished: {
                            bp.status = text.trim()
                            if (text.trim().indexOf("ok") === 0) bp.editing = -1
                            bp.reload()
                        }
                    }
                }

                Column {
                    id: bpHead
                    width: parent.width
                    spacing: 4
                    Text { text: Tr.t("Atalhos do Hyprland"); color: Colors.text; font.pixelSize: 18; font.bold: true }
                    Text {
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.pixelSize: 12
                        color: Colors.text
                        opacity: 0.65
                        text: bp.status !== "" ? bp.status : "Alterar: marque os modificadores e digite a tecla (Q, Return, Print, F5, comma, mouse:272...)"
                    }
                }

                ListView {
                    anchors.top: bpHead.bottom
                    anchors.topMargin: 12
                    anchors.bottom: parent.bottom
                    width: parent.width
                    clip: true
                    spacing: 6
                    boundsBehavior: Flickable.StopAtBounds
                    model: bp.list

                    delegate: Rectangle {
                        id: bd
                        required property var modelData
                        readonly property bool ed: bp.editing === modelData.id
                        width: ListView.view.width
                        height: ed ? 112 : 56
                        radius: 8
                        color: Colors.surface

                        Text {
                            x: 14; y: 9
                            width: parent.width - 330
                            elide: Text.ElideRight
                            text: bd.modelData.label
                            color: Colors.text
                            font.pixelSize: 14
                        }
                        Text {
                            x: 14; y: 31
                            width: parent.width - 330
                            elide: Text.ElideRight
                            text: bd.modelData.editable ? Tr.t("padrão: ") + bd.modelData.orig : "criada por um laço (não editável)"
                            color: Colors.text
                            opacity: 0.55
                            font.pixelSize: 11
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            y: 11
                            spacing: 8
                            Rectangle {
                                height: 32
                                width: ct.implicitWidth + 22
                                radius: 6
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                                Text {
                                    id: ct
                                    anchors.centerIn: parent
                                    text: bd.modelData.combo
                                    color: Colors.text
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }
                            Btn {
                                visible: bd.modelData.editable && !bd.ed && bd.modelData.combo !== bd.modelData.orig
                                text: Tr.t("Restaurar")
                                onClicked: bp.save(bd.modelData.id, bd.modelData.orig)
                            }
                            Btn {
                                visible: bd.modelData.editable && !bd.ed
                                text: Tr.t("Alterar")
                                onClicked: bp.startEdit(bd.modelData)
                            }
                        }

                        Row {
                            visible: bd.ed
                            x: 14; y: 62
                            spacing: 8
                            Repeater {
                                model: ["SUPER", "CTRL", "ALT", "SHIFT"]
                                Rectangle {
                                    required property string modelData
                                    readonly property bool on: bp.hasMod(modelData)
                                    height: 32; width: 70; radius: 6
                                    color: on ? Colors.accent : Colors.card
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        font.pixelSize: 12
                                        color: parent.on ? Colors.onAccent : Colors.text
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: bp.toggleMod(parent.modelData)
                                    }
                                }
                            }
                            Rectangle {
                                height: 32; width: 150; radius: 6
                                color: Colors.card
                                border.width: 1
                                border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5)
                                TextInput {
                                    id: keyIn
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: Colors.text
                                    font.pixelSize: 13
                                    clip: true
                                    onTextChanged: if (bd.ed) bp.eKey = text
                                    Connections {
                                        target: bd
                                        function onEdChanged() { if (bd.ed) { keyIn.text = bp.eKey; keyIn.forceActiveFocus() } }
                                    }
                                }
                            }
                            Btn { text: Tr.t("Salvar"); onClicked: bp.save(bd.modelData.id, bp.combo()) }
                            Btn { text: Tr.t("Cancelar"); onClicked: bp.editing = -1 }
                        }
                    }
                }
            }

            // ---- Widgets ----
            Flickable {
                anchors.fill: parent; anchors.margins: 28
                visible: win.tab === 5
                clip: true
                contentHeight: c5.height + 20
                Column {
                    id: c5
                    width: parent.width

                    SHead { label: Tr.t("PAINÉIS") }
                    SRow {
                        label: Tr.t("Arredondamento das bordas")
                        def: Tr.t("10 px")
                        Sld { from: 0; to: 50; step: 1; value: Settings.wRadius; valueText: Math.round(value) + " px"; onMoved: v => Settings.wRadius = Math.round(v) }
                    }
                    SRow {
                        label: Tr.t("Tamanho da borda")
                        def: Tr.t("1 px")
                        Sld { from: 0; to: 20; step: 1; value: Settings.wBorder; valueText: Math.round(value) + " px"; onMoved: v => Settings.wBorder = Math.round(v) }
                    }
                    SRow {
                        label: Tr.t("Fonte")
                        hint: Tr.t("Só dos painéis (a da barra fica em Aparência)")
                        def: Tr.t("Iosevka")
                        Seg {
                            options: [{ v: "default", t: Tr.t("Iosevka") }, { v: "other", t: Tr.t("Outras fontes") }]
                            current: Settings.wFontMode
                            onPicked: v => Settings.wFontMode = v
                        }
                    }
                    Item {
                        id: wFontBox
                        visible: Settings.wFontMode === "other"
                        property string q: ""
                        width: parent.width
                        height: visible ? 290 : 0
                        Rectangle {
                            y: 4; width: parent.width; height: 32; radius: 6; color: Colors.surface
                            TextInput {
                                id: wFin
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.text; font.pixelSize: 13; clip: true
                                onTextChanged: wFontBox.q = text.toLowerCase()
                            }
                            Text {
                                anchors.fill: wFin; verticalAlignment: Text.AlignVCenter
                                visible: wFin.text === ""
                                text: "Buscar entre " + win.fontList.length + " fontes instaladas..."
                                color: Colors.text; opacity: 0.5; font.pixelSize: 13
                            }
                        }
                        ListView {
                            y: 44; width: parent.width; height: parent.height - 48
                            clip: true; spacing: 4; boundsBehavior: Flickable.StopAtBounds
                            model: win.fontList.filter(f => f.toLowerCase().indexOf(wFontBox.q) >= 0)
                            delegate: Rectangle {
                                required property string modelData
                                readonly property bool sel: Settings.wFontChoice === modelData
                                width: ListView.view.width; height: 32; radius: 6
                                color: sel ? Colors.accent : Colors.surface
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter; x: 12
                                    text: modelData; font.family: modelData; font.pixelSize: 15
                                    color: parent.sel ? Colors.onAccent : Colors.text
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.wFontChoice = modelData }
                            }
                        }
                    }
                    SRow {
                        label: Tr.t("Tamanho da fonte")
                        def: Tr.t("Média")
                        Seg {
                            options: [{ v: "small", t: Tr.t("Pequena") }, { v: "medium", t: Tr.t("Média") }, { v: "large", t: Tr.t("Grande") }]
                            current: Settings.wFontSizeMode
                            onPicked: v => Settings.wFontSizeMode = v
                        }
                    }

                    SHead { label: Tr.t("LANÇADOR DE APLICATIVOS  ·  atalho: SUPER + D") }
                    SRow {
                        label: Tr.t("› Posição do lançador")
                        def: Tr.t("Centro")
                        Seg {
                            options: [{ v: "center", t: Tr.t("Centro") }, { v: "top", t: Tr.t("Cima") }, { v: "bottom", t: Tr.t("Baixo") }, { v: "left", t: Tr.t("Esquerda") }, { v: "right", t: Tr.t("Direita") }]
                            current: Settings.launcherPos
                            onPicked: v => Settings.launcherPos = v
                        }
                    }
                    SRow {
                        label: Tr.t("› Modo")
                        hint: Tr.t("Mínimo: barrinha de busca com resultados em linha")
                        def: Tr.t("Padrão")
                        Seg {
                            options: [{ v: "minimal", t: Tr.t("Mínimo") }, { v: "default", t: Tr.t("Padrão") }]
                            current: Settings.launcherMode
                            onPicked: v => Settings.launcherMode = v
                        }
                    }

                    SHead { label: Tr.t("WALLPAPERS E DASHBOARD") }
                    SRow {
                        label: Tr.t("Pasta dos Wallpapers")
                        hint: Tr.t("Salva aqui; ainda falta ligar ao seletor (SUPER+Tab)")
                        def: Tr.t("~/Imagens/Wallpapers")
                        Rectangle {
                            width: 300; height: 32; radius: 6; color: Colors.surface
                            TextInput {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.text; font.pixelSize: 13; clip: true
                                text: Settings.wallDir
                                onEditingFinished: Settings.wallDir = text
                            }
                        }
                    }
                    SRow {
                        label: Tr.t("Ícone do dashboard")
                        hint: Tr.t("Ícone do painel que abre pelo logo da barra")
                        def: Tr.t("Arch")
                        Seg {
                            options: [{ v: "arch", t: Tr.t("Arch") }, { v: "hyprland", t: Tr.t("Hyprland") }, { v: "hyprnova", t: Tr.t("Hyprnova") }, { v: "linux", t: Tr.t("Linux") }]
                            current: Settings.dashLogo
                            onPicked: v => Settings.dashLogo = v
                        }
                    }

                    SHead { label: Tr.t("REDE") }
                    SRow {
                        label: Tr.t("Gerenciador de internet na barra")
                        hint: Tr.t("Ícone de rede ao lado da bandeja")
                        def: Tr.t("Ativado")
                        Seg {
                            options: [{ v: true, t: Tr.t("Ativado") }, { v: false, t: Tr.t("Desativado") }]
                            current: Settings.netOn
                            onPicked: v => Settings.netOn = v
                        }
                    }
                }
            }

            // ---- Fastfetch ----
            Flickable {
                id: ffPage
                anchors.fill: parent; anchors.margins: 28
                visible: win.tab === 6
                clip: true
                contentHeight: c6.height + 20
                Process { id: ffProc }
                Process { id: ffPrev; command: ["kitty", "--hold", "fastfetch"] }
                Timer {
                    id: ffT
                    interval: 500
                    onTriggered: { ffProc.command = [Quickshell.env("HOME") + "/.local/bin/fastfetch-apply"]; ffProc.running = true }
                }
                function toggleMod(id) {
                    const a = Array.from(Settings.ffMods)
                    const i = a.indexOf(id)
                    if (i >= 0) a.splice(i, 1); else a.push(id)
                    Settings.ffMods = a
                    ffT.restart()
                }
                Column {
                    id: c6
                    width: parent.width

                    SHead { label: Tr.t("VISUAL") }
                    SRow {
                        label: Tr.t("Nome no título")
                        def: Tr.t("Ryan Matsui")
                        Rectangle {
                            width: 240; height: 32; radius: 6; color: Colors.surface
                            TextInput {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.text; font.pixelSize: 13; clip: true
                                text: Settings.ffName
                                onEditingFinished: { Settings.ffName = text; ffT.restart() }
                            }
                        }
                    }
                    SRow {
                        label: Tr.t("Linha separadora")
                        def: Tr.t("Ligada")
                        Seg {
                            options: [{ v: true, t: Tr.t("Ligada") }, { v: false, t: Tr.t("Desligada") }]
                            current: Settings.ffSep
                            onPicked: v => { Settings.ffSep = v; ffT.restart() }
                        }
                    }

                    SHead { label: Tr.t("MÓDULOS  ·  clique para ligar ou desligar") }
                    Item {
                        width: parent.width
                        height: modFlow.implicitHeight + 16
                        Flow {
                            id: modFlow
                            y: 8
                            width: parent.width
                            spacing: 8
                            Repeater {
                                model: [
                                    { id: "os", t: Tr.t("Sistema") }, { id: "host", t: Tr.t("Host") }, { id: "kernel", t: Tr.t("Kernel") },
                                    { id: "uptime", t: Tr.t("Uptime") }, { id: "packages", t: Tr.t("Pacotes") }, { id: "shell", t: Tr.t("Shell") },
                                    { id: "display", t: Tr.t("Resolução") }, { id: "wm", t: Tr.t("WM") }, { id: "terminal", t: Tr.t("Terminal") },
                                    { id: "cpu", t: Tr.t("CPU") }, { id: "gpu", t: Tr.t("GPU") }, { id: "memory", t: Tr.t("Memória") },
                                    { id: "disk", t: Tr.t("Disco") }, { id: "localip", t: Tr.t("IP local") }, { id: "battery", t: Tr.t("Bateria") },
                                    { id: "colors", t: Tr.t("Paleta de cores") }
                                ]
                                Rectangle {
                                    required property var modelData
                                    readonly property bool on: Settings.ffMods.indexOf(modelData.id) >= 0
                                    height: 32
                                    width: lbl.implicitWidth + 28
                                    radius: 8
                                    color: on ? Colors.accent : Colors.surface
                                    Text {
                                        id: lbl
                                        anchors.centerIn: parent
                                        text: parent.modelData.t
                                        font.pixelSize: 13
                                        color: parent.on ? Colors.onAccent : Colors.text
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ffPage.toggleMod(parent.modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    SRow {
                        label: Tr.t("Pré-visualizar")
                        hint: Tr.t("Abre um terminal com o fastfetch")
                        Btn { text: Tr.t("Abrir"); onClicked: ffPrev.running = true }
                    }
                }
            }

            // ---- Sobre ----
            Flickable {
                id: aboutPage
                anchors.fill: parent; anchors.margins: 28
                visible: win.tab === 7
                clip: true
                contentHeight: c7.height + 20
                property var info: ({})
                onVisibleChanged: if (visible) aboutP.running = true
                Process {
                    id: aboutP
                    command: ["sh", Quickshell.env("HOME") + "/.local/bin/qs-about"]
                    stdout: StdioCollector {
                        onStreamFinished: {
                            const m = {}
                            text.trim().split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) m[l.slice(0, i)] = l.slice(i + 1) })
                            aboutPage.info = m
                        }
                    }
                }
                Column {
                    id: c7
                    width: parent.width

                    SHead { label: Tr.t("IDIOMA") }
                    SRow {
                        label: Tr.t("Língua / Language")
                        hint: Tr.t("Vale para o painel de configurações e os painéis")
                        def: Tr.t("Português")
                        Seg {
                            options: [{ v: "pt", t: Tr.t("Português") }, { v: "en", t: Tr.t("English") }]
                            current: Settings.lang
                            onPicked: v => Settings.lang = v
                        }
                    }

                    SHead { label: Tr.t("ESPECIFICAÇÕES DO SISTEMA") }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Sistema"); value: aboutPage.info.os || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Kernel"); value: aboutPage.info.kernel || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Placa/Modelo"); value: aboutPage.info.host || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("CPU"); value: aboutPage.info.cpu || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("GPU"); value: aboutPage.info.gpu || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Memória"); value: aboutPage.info.ram || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Disco (/)"); value: aboutPage.info.disk || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Tela"); value: aboutPage.info.screen || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Tempo ligado"); value: aboutPage.info.uptime || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Hyprland"); value: aboutPage.info.hypr || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Quickshell"); value: aboutPage.info.qs || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Shell do usuário"); value: aboutPage.info.shell || "-" }
                    DataRow { width: parent.width; fonte: Settings.fontFamily; label: Tr.t("Pacotes"); value: aboutPage.info.pkgs || "-" }
                }
            }

            // ---- Notificações ----
            Flickable {
                anchors.fill: parent; anchors.margins: 28
                visible: win.tab === 2
                clip: true
                contentHeight: c2.height
                Column {
                    id: c2
                    width: parent.width
                    SRow {
                        label: Tr.t("Não perturbe")
                        hint: Tr.t("Esconde os popups (continuam na central)")
                        Toggle { on: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
                    }
                    SRow {
                        label: Tr.t("Posição dos popups")
                        Seg {
                            options: [
                                { v: "top-right", t: Tr.t("↗") }, { v: "top-left", t: Tr.t("↖") },
                                { v: "bottom-right", t: Tr.t("↘") }, { v: "bottom-left", t: Tr.t("↙") }
                            ]
                            current: Settings.notifPosition
                            onPicked: v => Settings.notifPosition = v
                        }
                    }
                    SRow {
                        label: Tr.t("Duração")
                        Sld { from: 2; to: 15; step: 1; value: Settings.notifTimeout; valueText: Math.round(value) + " s"; onMoved: v => Settings.notifTimeout = v }
                    }
                    SRow {
                        label: Tr.t("Máximo de popups na tela")
                        Sld { from: 1; to: 8; step: 1; value: Settings.notifMax; valueText: String(Math.round(value)); onMoved: v => Settings.notifMax = v }
                    }
                }
            }
        }
    }
}
