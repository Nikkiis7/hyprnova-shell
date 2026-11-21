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
    target: "windows"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return
      win.open = !win.open
    }
  }

  property bool open: false
  property bool shown: open
  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily
  property var groups: []
  property int activeWs: 0

  function wsName(g) {
    return g.id < 0 ? g.name.replace("special:", "") : "Workspace " + g.id
  }

  function parse(t) {
    const parts = t.split("@@@\n")
    if (parts.length < 2) return
    let clients = []
    try { clients = JSON.parse(parts[0]) } catch (e) { return }
    let aw = 0
    try { aw = JSON.parse(parts[1]).id } catch (e) {}
    const map = {}
    clients.forEach(c => {
      if (!c.mapped) return
      const id = c.workspace.id
      if (!map[id]) map[id] = { id: id, name: c.workspace.name, wins: [] }
      map[id].wins.push({ addr: c.address, cls: c["class"], title: c.title || c["class"] })
    })
    win.groups = Object.values(map).sort((a, b) => a.id - b.id)
    win.activeWs = aw
  }

  function focusWindow(addr) {
    Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.focus({ window = \"address:" + addr + "\" })"])
    win.open = false
  }

  function closeWindow(addr) {
    Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.close({ window = \"address:" + addr + "\" })"])
  }

  Process {
    id: proc
    command: ["sh", "-c", "hyprctl clients -j; echo @@@; hyprctl activeworkspace -j"]
    stdout: StdioCollector {
      onStreamFinished: win.parse(this.text)
    }
  }

  Timer {
    interval: 1500
    repeat: true
    running: win.open
    triggeredOnStart: true
    onTriggered: if (!proc.running) proc.running = true
  }

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  exclusionMode: ExclusionMode.Ignore

  anchors {
    top: Pos.a("top", Pos.grp(Settings.windowPlace, "start"))
    bottom: Pos.a("bottom", Pos.grp(Settings.windowPlace, "start"))
    left: Pos.a("left", Pos.grp(Settings.windowPlace, "start"))
    right: Pos.a("right", Pos.grp(Settings.windowPlace, "start"))
  }
  margins {
    top: Pos.m("top", Pos.grp(Settings.windowPlace, "start"), 234, "start")
    bottom: Pos.m("bottom", Pos.grp(Settings.windowPlace, "start"), 234, "start")
    left: Pos.m("left", Pos.grp(Settings.windowPlace, "start"), 234, "start")
    right: Pos.m("right", Pos.grp(Settings.windowPlace, "start"), 234, "start")
  }

  implicitWidth: 400
  implicitHeight: card.height + 6
  color: "transparent"

  Rectangle {
    id: card
    width: parent.width
    height: Math.min(content.implicitHeight + 28, 520)
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

    Flickable {
      anchors.fill: parent
      anchors.margins: 14
      contentWidth: width
      contentHeight: content.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: content
        width: parent.width
        spacing: 10

        Text {
          visible: win.groups.length === 0
          text: Tr.t("Nenhuma janela aberta")
          color: Colors.textDim
          font.family: win.fonte
          font.pixelSize: Math.round(13 * Settings.wScale)
        }

        Repeater {
          model: win.groups

          Column {
            id: grp
            width: content.width
            spacing: 4
            property var group: modelData

            Item {
              width: grp.width
              height: 20

              Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: win.wsName(grp.group)
                color: grp.group.id === win.activeWs ? win.accent : Colors.text
                font.family: win.fonte
                font.pixelSize: Math.round(13 * Settings.wScale)
                font.bold: true
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: grp.group.wins.length + (grp.group.wins.length === 1 ? " janela" : " janelas")
                color: Colors.textFaint
                font.family: win.fonte
                font.pixelSize: Math.round(11 * Settings.wScale)
              }
            }

            Repeater {
              model: grp.group.wins

              Rectangle {
                width: grp.width
                height: 28
                radius: 6
                color: rowArea.containsMouse ? Colors.surfaceHi : Colors.surface
                Behavior on color { ColorAnimation { duration: Math.round(120 * Settings.animMul) } }

                MouseArea {
                  id: rowArea
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: win.focusWindow(modelData.addr)
                }

                Text {
                  anchors.left: parent.left
                  anchors.leftMargin: 10
                  anchors.right: classText.left
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.title
                  color: Colors.text
                  font.family: win.fonte
                  font.pixelSize: Math.round(12 * Settings.wScale)
                  elide: Text.ElideRight
                }

                Text {
                  id: classText
                  anchors.right: closeBtn.left
                  anchors.rightMargin: 8
                  anchors.verticalCenter: parent.verticalCenter
                  text: modelData.cls
                  color: Colors.textDim
                  font.family: win.fonte
                  font.pixelSize: Math.round(11 * Settings.wScale)
                }

                Rectangle {
                  id: closeBtn
                  anchors.right: parent.right
                  anchors.rightMargin: 4
                  anchors.verticalCenter: parent.verticalCenter
                  width: 22
                  height: 22
                  radius: 5
                  color: closeArea.containsMouse ? "#ff6b9d" : "transparent"
                  Behavior on color { ColorAnimation { duration: Math.round(120 * Settings.animMul) } }

                  Text {
                    anchors.centerIn: parent
                    text: Tr.t("󰅖")
                    color: closeArea.containsMouse ? Colors.onAccent : Colors.textDim
                    font.family: win.fonte
                    font.pixelSize: Math.round(13 * Settings.wScale)
                  }

                  MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: win.closeWindow(modelData.addr)
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
