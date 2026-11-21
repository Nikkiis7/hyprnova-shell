pragma Singleton
import QtQuick

QtObject {
    readonly property string p: Settings.barPosition
    readonly property bool vert: p === "left" || p === "right"
    readonly property int gap: Settings.barStyle === "docked" ? (Settings.mini ? 48 : 56) : (Settings.mini ? 58 : 66)

    // grupo valido ("start"/"center"/"end") ou o padrao quando o modulo esta oculto
    function grp(v, def) { return (v === "start" || v === "center" || v === "end") ? v : def }

    // O painel do grupo g ancora nesta borda?
    function a(edge, g) {
        if (edge === p) return true
        if (g === "center") return false
        const first = (g === "start" || g === "a")
        if (vert) return first ? edge === "top" : edge === "bottom"
        return first ? edge === "left" : edge === "right"
    }
    // Margem: encostada na barra = gap; no grupo de origem mantem o deslocamento antigo; senao 14
    function m(edge, g, off, def) {
        if (edge === p) return gap
        if (vert) return 14
        return g === def ? off : 14
    }
    function nm(edge) { return edge === p ? (Settings.barStyle === "docked" ? 62 : 72) : 14 }
}
