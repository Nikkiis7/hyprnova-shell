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
    target: "archinfo"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return
      win.open = !win.open
    }
  }

  property bool open: false
  property bool shown: open
  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily
  property var info: ({})

  function parse(t) {
    const m = {}
    t.trim().split("\n").forEach(l => {
      const i = l.indexOf("=")
      if (i > 0) m[l.slice(0, i)] = l.slice(i + 1)
    })
    win.info = m
  }

  Process {
    id: proc
    command: ["sh", "-c", "sh $HOME/.config/quickshell/info.sh"]
    stdout: StdioCollector {
      onStreamFinished: win.parse(this.text)
    }
  }

  Timer {
    interval: 30000
    repeat: true
    running: win.open
    triggeredOnStart: true
    onTriggered: if (!proc.running) proc.running = true
  }

  // ---- estatisticas e central de notificacoes ----
  property var stats: ({})
  property var notifs: Notifs.recent
  property bool dnd: Notifs.dnd

  function parseStats(t) {
    const m = {}
    t.trim().split("\n").forEach(l => {
      const i = l.indexOf("=")
      if (i > 0) m[l.slice(0, i)] = l.slice(i + 1)
    })
    win.stats = m
  }

  function refreshAll() {
    if (!statsProc.running) statsProc.running = true
  }

  function run(cmd) {
    act.command = cmd
    act.running = true
  }

  Process {
    id: statsProc
    command: ["sh", "-c", "sh $HOME/.config/quickshell/stats.sh"]
    stdout: StdioCollector { onStreamFinished: win.parseStats(this.text) }
  }
  Process {
    id: act
    onRunningChanged: if (!running) win.refreshAll()
  }
  Timer {
    interval: 3000
    repeat: true
    running: win.open
    triggeredOnStart: true
    onTriggered: win.refreshAll()
  }

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: Pos.a("top", Pos.grp(Settings.logoPlace, "start"))
    bottom: Pos.a("bottom", Pos.grp(Settings.logoPlace, "start"))
    left: Pos.a("left", Pos.grp(Settings.logoPlace, "start"))
    right: Pos.a("right", Pos.grp(Settings.logoPlace, "start"))
  }
  margins {
    top: Pos.m("top", Pos.grp(Settings.logoPlace, "start"), 14, "start")
    bottom: Pos.m("bottom", Pos.grp(Settings.logoPlace, "start"), 14, "start")
    left: Pos.m("left", Pos.grp(Settings.logoPlace, "start"), 14, "start")
    right: Pos.m("right", Pos.grp(Settings.logoPlace, "start"), 14, "start")
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

      Row {
        spacing: 12

        Rectangle {
          width: 52
          height: 52
          radius: 26
          color: Colors.surface
          border.color: win.accent
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: Settings.dashLogo === "hyprland" ? "\uf359" : (Settings.dashLogo === "hyprnova" ? "\ue22e" : (Settings.dashLogo === "linux" ? "\uf17c" : "\udb82\udcc7"))
            color: win.accent
            font.family: win.fonte
            font.pixelSize: Math.round(28 * Settings.wScale)
          }
        }

        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Text {
            text: win.info.user || ""
            color: Colors.text
            font.family: win.fonte
            font.pixelSize: Math.round(16 * Settings.wScale)
            font.bold: true
          }

          Text {
            text: (win.info.user || "") + "@" + (win.info.host || "")
            color: Colors.textDim
            font.family: win.fonte
            font.pixelSize: Math.round(12 * Settings.wScale)
          }
        }
      }

      Rectangle {
        width: content.width
        height: 1
        color: Colors.border
      }

      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Sistema");   value: win.info.os || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Kernel");    value: win.info.kernel || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Uptime");    value: win.info.uptime || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Pacotes");   value: win.info.pkgs || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Shell");     value: win.info.shell || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Ambiente");  value: win.info.wm || "-" }

      Rectangle {
        width: content.width
        height: 1
        color: Colors.border
      }

      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("CPU");       value: win.info.cpu || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("GPU");       value: win.info.gpu || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Disco (/)"); value: win.info.disk || "-" }

      Rectangle { width: content.width; height: 1; color: Colors.border }

      Text { text: Tr.t("Temperaturas"); color: Colors.textDim; font.family: win.fonte; font.pixelSize: Math.round(12 * Settings.wScale) }
      TempBar { width: content.width; fonte: win.fonte; label: Tr.t("CPU"); temp: Number(win.stats.t_cpu || 0) }
      TempBar { width: content.width; fonte: win.fonte; label: Tr.t("GPU"); temp: Number(win.stats.t_gpu || 0) }
      TempBar { width: content.width; fonte: win.fonte; label: Tr.t("SSD"); temp: Number(win.stats.t_ssd || 0); warn: 70 }

      Rectangle { width: content.width; height: 1; color: Colors.border }

      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Uso da GPU"); value: win.stats.gpu_use ? win.stats.gpu_use + "%" : "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("VRAM");       value: win.stats.vram || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("RAM");        value: win.stats.ram || "-" }
      DataRow { width: content.width; fonte: win.fonte; label: Tr.t("Carga");      value: win.stats.load || "-" }

      Rectangle { width: content.width; height: 1; color: Colors.border }

      Item {
        width: content.width
        height: 24
        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: "Notificações" + (win.notifs.length > 0 ? "  (" + win.notifs.length + ")" : "")
          color: Colors.textDim
          font.family: win.fonte
          font.pixelSize: Math.round(12 * Settings.wScale)
        }
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6
          MiniBtn {
            text: win.dnd ? "\uf1f6  Silenciado" : "\uf0f3  Não perturbe"
            active: win.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
          }
          MiniBtn {
            text: Tr.t("Limpar")
            onClicked: Notifs.clearAll()
          }
        }
      }

      Repeater {
        model: win.notifs
        delegate: Rectangle {
          id: nItem
          required property var modelData
          width: content.width
          height: nCol.implicitHeight + 14
          radius: 7
          color: Colors.surface

          Column {
            id: nCol
            x: 10
            y: 7
            width: parent.width - 46
            spacing: 1
            Text {
              width: parent.width
              text: nItem.modelData.appName
              color: Colors.textFaint
              font.family: win.fonte
              font.pixelSize: Math.round(11 * Settings.wScale)
              elide: Text.ElideRight
            }
            Text {
              width: parent.width
              text: nItem.modelData.summary
              color: Colors.text
              font.family: win.fonte
              font.pixelSize: Math.round(13 * Settings.wScale)
              font.bold: true
              elide: Text.ElideRight
            }
            Text {
              visible: nItem.modelData.body !== ""
              width: parent.width
              text: nItem.modelData.body
              color: Colors.textDim
              font.family: win.fonte
              font.pixelSize: Math.round(12 * Settings.wScale)
              wrapMode: Text.Wrap
              maximumLineCount: 2
              elide: Text.ElideRight
            }
          }
          MiniBtn {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 7
            implicitHeight: 22
            text: Tr.t("\uf00d")
            onClicked: nItem.modelData.dismiss()
          }
        }
      }

      Text {
        visible: win.notifs.length === 0
        text: Tr.t("Sem notificações")
        color: Colors.textFaint
        font.family: win.fonte
        font.pixelSize: Math.round(12 * Settings.wScale)
      }
    }
  }
}
