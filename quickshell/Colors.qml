pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property color accent: "#b48cff"
  readonly property real hue: accent.hslHue
  readonly property bool light: Settings.themeMode === "light"

  readonly property color accentLight: Qt.lighter(accent, 1.35)
  readonly property color card:        light ? Qt.hsla(hue, 0.35, 0.95, 0.95) : Qt.hsla(hue, 0.44, 0.09, 0.95)
  readonly property color surface:     light ? Qt.hsla(hue, 0.30, 0.90, 1)    : Qt.hsla(hue, 0.43, 0.15, 1)
  readonly property color surfaceHi:   light ? Qt.hsla(hue, 0.30, 0.84, 1)    : Qt.hsla(hue, 0.42, 0.23, 1)
  readonly property color border:      light ? Qt.hsla(hue, 0.25, 0.78, 1)    : Qt.hsla(hue, 0.35, 0.22, 1)
  readonly property color text:        light ? Qt.hsla(hue, 0.35, 0.12, 1)    : Qt.hsla(hue, 1.0, 0.94, 1)
  readonly property color textDim:     light ? Qt.hsla(hue, 0.20, 0.35, 1)    : Qt.hsla(hue, 0.20, 0.65, 1)
  readonly property color textFaint:   light ? Qt.hsla(hue, 0.15, 0.55, 1)    : Qt.hsla(hue, 0.20, 0.40, 1)
  readonly property color onAccent:    Qt.hsla(hue, 0.44, 0.09, 0.88)
  readonly property color onAccentDim: Qt.hsla(hue, 0.44, 0.09, 0.69)

  FileView {
    path: Quickshell.env("HOME") + "/.cache/accent-color"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const t = text().trim()
      if (/^#[0-9a-fA-F]{6}$/.test(t)) root.accent = t
    }
  }
}
