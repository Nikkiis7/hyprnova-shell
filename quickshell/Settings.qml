pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Aparência
    property alias themeMode: a.themeMode
    property alias radius: a.radius
    property alias barOpacity: a.barOpacity
    property alias barHeight: a.barHeight
    property alias fontSize: a.fontSize
    // Barra
    property alias barPosition: a.barPosition
    property alias logoStyle: a.logoStyle
    property alias cpuRamPlace: a.cpuRamPlace
    property alias windowPlace: a.windowPlace
    property alias volumePlace: a.volumePlace
    property alias wsStyle: a.wsStyle
    property alias autoHide: a.autoHide
    property alias logoPlace: a.logoPlace
    property alias wsPlace: a.wsPlace
    property alias clockPlace: a.clockPlace
    property alias powerPlace: a.powerPlace
    property alias hyprGlyph: a.hyprGlyph
    property alias barStyle: a.barStyle
    property alias musicPlace: a.musicPlace
    property alias barRadius: a.barRadius
    property alias moduleRadius: a.moduleRadius
    property alias moduleOpacity: a.moduleOpacity
    property alias uiOpacity: a.uiOpacity
    property alias lang: a.lang
    property alias ffLogo: a.ffLogo
    property alias ffName: a.ffName
    property alias ffKeyColor: a.ffKeyColor
    property alias ffSep: a.ffSep
    property alias ffMods: a.ffMods
    property alias kittyTransp: a.kittyTransp
    property alias wRadius: a.wRadius
    property alias wBorder: a.wBorder
    property alias wFontMode: a.wFontMode
    property alias wFontChoice: a.wFontChoice
    property alias wFontSizeMode: a.wFontSizeMode
    property alias launcherPos: a.launcherPos
    property alias launcherMode: a.launcherMode
    property alias wallDir: a.wallDir
    property alias dashPhotoMode: a.dashPhotoMode
    property alias dashPhotoFile: a.dashPhotoFile
    property alias dashLogo: a.dashLogo
    property alias netOn: a.netOn
    readonly property string wFontFamily: (wFontMode === "other" && wFontChoice !== "") ? wFontChoice : fontFamily
    readonly property real wScale: wFontSizeMode === "small" ? 0.85 : (wFontSizeMode === "large" ? 1.15 : 1.0)
    property alias hLayout: a.hLayout
    property alias hBorder: a.hBorder
    property alias hRound: a.hRound
    property alias hOpacity: a.hOpacity
    property alias hGapsIn: a.hGapsIn
    property alias hGapsOut: a.hGapsOut
    property alias hWinBlur: a.hWinBlur
    property alias hAnimOn: a.hAnimOn
    property alias hSingle: a.hSingle
    property alias hHideInactive: a.hHideInactive
    property alias barSize: a.barSize
    readonly property bool mini: barSize === "minimal"
    readonly property int chipH: mini ? 33 : 37
    readonly property int trayIcon: mini ? 14 : 18
    readonly property real bs: mini ? 0.88 : 1.0
    property alias fontMode: a.fontMode
    property alias fontChoice: a.fontChoice
    property alias fontSizeMode: a.fontSizeMode
    property alias dockShow: a.dockShow
    property alias dockPosition: a.dockPosition
    property alias dockAutoHide: a.dockAutoHide
    property alias dockPinned: a.dockPinned
    property alias animMode: a.animMode
    property alias blurOn: a.blurOn
    readonly property real animMul: animMode === "simple" ? 0.3 : 1.0
    readonly property string fontFamily: (fontMode === "other" && fontChoice !== "") ? fontChoice : "Iosevka Nerd Font"
    readonly property real fontScale: fontSizeMode === "small" ? 0.85 : (fontSizeMode === "large" ? 1.15 : 1.0)
    property alias showWorkspaces: a.showWorkspaces
    property alias showWindow: a.showWindow
    property alias showMusic: a.showMusic
    property alias showCpuRam: a.showCpuRam
    property alias showVolume: a.showVolume
    property alias showTray: a.showTray
    property alias showDate: a.showDate
    property alias clock24h: a.clock24h
    // Notificações
    property alias notifPosition: a.notifPosition
    property alias notifTimeout: a.notifTimeout
    property alias notifMax: a.notifMax

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }

        adapter: JsonAdapter {
            id: a
            property string themeMode: "dark"
            property int radius: 5
            property real barOpacity: 0.88
            property int barHeight: 52
            property int fontSize: 20

            property string barPosition: "top"
            property string logoStyle: "arch"
            property string cpuRamPlace: "start"
            property string windowPlace: "start"
            property string volumePlace: "end"
            property string wsStyle: "kanji"
            property bool autoHide: false
            property string logoPlace: "start"
            property string wsPlace: "center"
            property string clockPlace: "end"
            property string powerPlace: "end"
            property string hyprGlyph: ""
            property string barStyle: "floating"
            property string musicPlace: "end"
            property int barRadius: 5
            property int moduleRadius: 5
            property int moduleOpacity: 10
            property real uiOpacity: 0.88
            property string lang: "pt"
            property string ffLogo: "current"
            property string ffName: "Ryan Matsui"
            property string ffKeyColor: "magenta"
            property bool ffSep: true
            property list<string> ffMods: ["os", "host", "kernel", "uptime", "packages", "shell", "wm", "terminal", "cpu", "gpu", "memory", "disk"]
            property int kittyTransp: 0
            property int wRadius: 10
            property int wBorder: 1
            property string wFontMode: "default"
            property string wFontChoice: ""
            property string wFontSizeMode: "medium"
            property string launcherPos: "center"
            property string launcherMode: "default"
            property string wallDir: "~/Imagens/Wallpapers"
            property string dashPhotoMode: "logo"
            property string dashPhotoFile: ""
            property string dashLogo: "arch"
            property bool netOn: true
            property string hLayout: "dwindle"
            property int hBorder: 3
            property int hRound: 1
            property int hOpacity: 100
            property int hGapsIn: 5
            property int hGapsOut: 10
            property bool hWinBlur: true
            property bool hAnimOn: true
            property bool hSingle: false
            property bool hHideInactive: false
            property string barSize: "default"
            property string fontMode: "default"
            property string fontChoice: ""
            property string fontSizeMode: "medium"
            property bool dockShow: false
            property string dockPosition: "bottom"
            property bool dockAutoHide: false
            property list<string> dockPinned: ["firefox", "kitty", "yazi", "spotify", "discord"]
            property string animMode: "complex"
            property bool blurOn: true
            property bool showWorkspaces: true
            property bool showWindow: true
            property bool showMusic: true
            property bool showCpuRam: true
            property bool showVolume: true
            property bool showTray: true
            property bool showDate: true
            property bool clock24h: true

            property string notifPosition: "top-right"
            property int notifTimeout: 5
            property int notifMax: 4
        }
    }
}
