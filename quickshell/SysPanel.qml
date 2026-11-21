import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

PanelWindow {
  id: win

  property real closedAt: 0

  HyprlandFocusGrab {
    windows: [win]
    active: win.open
    onCleared: {
      win.open = false
      win.closedAt = Date.now()
    }
  }

  IpcHandler {
    target: "sysinfo"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return
      win.open = !win.open
    }
  }

  property bool open: false
  property bool shown: open
  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily

  property real cpuTotal: 0
  property var cores: []
  property var prev: ({})
  property real memTotal: 1
  property real memUsed: 0
  property real memAvail: 0
  property real memCache: 0
  property real swapTotal: 0
  property real swapUsed: 0
  property string load: "-"
  property var topCpu: []
  property var topMem: []

  function gib(kb) { return (kb / 1048576).toFixed(1) + " GiB" }
  function pct(r) { return Math.round(r * 100) + "%" }

  function parseProcs(t) {
    const skip = ["ps", "sh", "head"]
    const out = []
    t.trim().split("\n").forEach(l => {
      const f = l.trim().split(/\s+/)
      if (f.length < 3) return
      const name = f.slice(2).join(" ")
      if (skip.indexOf(name) >= 0) return
      out.push({ name: name, cpu: f[0], mem: f[1] })
    })
    return out.slice(0, 3)
  }

  function parse(t) {
    const secs = t.split("@@@\n")
    if (secs.length < 5) return

    const cpuLines = secs[0].trim().split("\n")
    const newPrev = {}
    const list = []
    let total = 0
    for (let i = 0; i < cpuLines.length; i++) {
      const f = cpuLines[i].trim().split(/\s+/)
      const name = f[0]
      const v = f.slice(1).map(Number)
      const idle = v[3] + (v[4] || 0)
      let sum = 0
      for (let j = 0; j < Math.min(8, v.length); j++) sum += v[j]
      newPrev[name] = [idle, sum]
      const p = win.prev[name]
      let usage = 0
      if (p && sum - p[1] > 0) usage = 1 - (idle - p[0]) / (sum - p[1])
      usage = Math.max(0, Math.min(1, usage))
      if (name === "cpu") total = usage
      else list.push(usage)
    }
    win.prev = newPrev
    win.cpuTotal = total
    win.cores = list

    const m = {}
    secs[1].trim().split("\n").forEach(l => {
      const f = l.trim().split(/\s+/)
      m[f[0].replace(":", "")] = Number(f[1])
    })
    win.memTotal = m.MemTotal || 1
    win.memAvail = m.MemAvailable || 0
    win.memUsed = win.memTotal - win.memAvail
    win.memCache = (m.Cached || 0) + (m.Buffers || 0)
    win.swapTotal = m.SwapTotal || 0
    win.swapUsed = (m.SwapTotal || 0) - (m.SwapFree || 0)

    win.load = secs[2].trim().split(/\s+/).join("  ")
    win.topCpu = win.parseProcs(secs[3])
    win.topMem = win.parseProcs(secs[4])
  }

  Process {
    id: proc
    command: ["sh", "-c", "grep '^cpu' /proc/stat; echo @@@; grep -E '^(MemTotal|MemAvailable|Buffers|Cached|SwapTotal|SwapFree):' /proc/meminfo; echo @@@; cut -d' ' -f1-3 /proc/loadavg; echo @@@; ps -eo pcpu=,pmem=,comm= --sort=-pcpu | head -6; echo @@@; ps -eo pcpu=,pmem=,comm= --sort=-pmem | head -6"]
    stdout: StdioCollector {
      onStreamFinished: win.parse(this.text)
    }
  }

  Timer {
    interval: 2000
    repeat: true
    running: win.open
    triggeredOnStart: true
    onTriggered: if (!proc.running) proc.running = true
  }

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: Pos.a("top", Pos.grp(Settings.cpuRamPlace, "start"))
    bottom: Pos.a("bottom", Pos.grp(Settings.cpuRamPlace, "start"))
    left: Pos.a("left", Pos.grp(Settings.cpuRamPlace, "start"))
    right: Pos.a("right", Pos.grp(Settings.cpuRamPlace, "start"))
  }
  margins {
    top: Pos.m("top", Pos.grp(Settings.cpuRamPlace, "start"), 66, "start")
    bottom: Pos.m("bottom", Pos.grp(Settings.cpuRamPlace, "start"), 66, "start")
    left: Pos.m("left", Pos.grp(Settings.cpuRamPlace, "start"), 66, "start")
    right: Pos.m("right", Pos.grp(Settings.cpuRamPlace, "start"), 66, "start")
  }

  implicitWidth: 340
  implicitHeight: card.height + 6
  color: "transparent"

  Rectangle {
    id: card
    width: parent.width
    height: content.implicitHeight + 28
    radius: Settings.wRadius
    color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
    border.color: Colors.border
    border.width: Settings.wBorder

    opacity: win.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Math.round(450 * Settings.animMul); easing.type: Easing.OutCubic } }

    transform: Translate {
      y: win.shown ? 0 : -28
      Behavior on y { NumberAnimation { duration: Math.round(450 * Settings.animMul); easing.type: Easing.OutCubic } }
    }

    Column {
      id: content
      x: 14
      y: 14
      width: parent.width - 28
      spacing: 8

      // ---------- CPU ----------
      Item {
        width: content.width
        height: 20

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: Tr.t("CPU")
          color: Colors.text
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: win.pct(win.cpuTotal)
          color: win.accent
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true
        }
      }

      UsageBar {
        width: content.width
        ratio: win.cpuTotal
        accent: win.accent
      }

      Row {
        spacing: 3

        Repeater {
          model: win.cores.length

          Rectangle {
            width: (content.width - 3 * (win.cores.length - 1)) / Math.max(1, win.cores.length)
            height: 34
            radius: 3
            color: Colors.surfaceHi

            Rectangle {
              anchors.bottom: parent.bottom
              width: parent.width
              height: parent.height * (win.cores[index] || 0)
              radius: 3
              color: (win.cores[index] || 0) > 0.85 ? "#ff6b9d" : win.accent
              Behavior on height { NumberAnimation { duration: Math.round(300 * Settings.animMul) } }
            }
          }
        }
      }

      InfoRow {
        width: content.width
        fonte: win.fonte
        accent: win.accent
        label: win.cores.length + " threads"
        value: "carga " + win.load
      }

      Text {
        text: Tr.t("Mais usam CPU")
        color: Colors.textFaint
        font.family: win.fonte
        font.pixelSize: Math.round(11 * Settings.wScale)
      }

      Repeater {
        model: win.topCpu

        InfoRow {
          width: content.width
          fonte: win.fonte
          accent: win.accent
          strong: true
          label: modelData.name
          value: modelData.cpu + "%"
        }
      }

      Rectangle {
        width: content.width
        height: 1
        color: Colors.border
      }

      // ---------- Memória ----------
      Item {
        width: content.width
        height: 20

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: Tr.t("Memória")
          color: Colors.text
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true
        }

        Text {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          text: win.gib(win.memUsed) + " / " + win.gib(win.memTotal)
          color: win.accent
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true
        }
      }

      UsageBar {
        width: content.width
        ratio: win.memUsed / win.memTotal
        accent: win.accent
      }

      InfoRow {
        width: content.width
        fonte: win.fonte
        accent: win.accent
        label: Tr.t("Disponível")
        value: win.gib(win.memAvail)
      }

      InfoRow {
        width: content.width
        fonte: win.fonte
        accent: win.accent
        label: Tr.t("Cache e buffers")
        value: win.gib(win.memCache)
      }

      InfoRow {
        width: content.width
        fonte: win.fonte
        accent: win.accent
        label: Tr.t("Swap")
        value: win.swapTotal > 0 ? win.gib(win.swapUsed) + " / " + win.gib(win.swapTotal) : "desligado"
      }

      Text {
        text: Tr.t("Mais usam memória")
        color: Colors.textFaint
        font.family: win.fonte
        font.pixelSize: Math.round(11 * Settings.wScale)
      }

      Repeater {
        model: win.topMem

        InfoRow {
          width: content.width
          fonte: win.fonte
          accent: win.accent
          strong: true
          label: modelData.name
          value: modelData.mem + "%"
        }
      }
    }
  }
}
