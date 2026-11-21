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
    target: "wallpaper"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return
      win.open = !win.open
    }
  }

  property bool open: false
  property bool shown: open
  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily
  property string dir: (Settings.wallDir.indexOf("~") === 0 ? Quickshell.env("HOME") + Settings.wallDir.slice(1) : Settings.wallDir)
  property var images: []
  property string current: ""

  function parse(t) {
    const i = t.indexOf("@@@\n")
    if (i < 0) return
    win.current = t.slice(0, i).trim()
    win.images = t.slice(i + 4).trim().split("\n").filter(l => l !== "")
  }

  function apply(path) {
    Quickshell.execDetached(["sh", Quickshell.env("HOME") + "/.config/quickshell/setwall.sh", path])
    win.current = path
  }

  function baseName(p) { return p.split("/").pop() }

  Process {
    id: lister
    command: ["sh", "-c", "cat \"$HOME/.cache/current-wallpaper\" 2>/dev/null; echo; echo @@@; find \"$1\" -maxdepth 2 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort", "sh", win.dir]
    stdout: StdioCollector {
      onStreamFinished: win.parse(this.text)
    }
  }

  // restaura o último wallpaper escolhido ao iniciar
  Timer {
    interval: 2500
    running: true
    onTriggered: restore.running = true
  }

  Process {
    id: restore
    command: ["sh", "-c", "f=\"$HOME/.cache/current-wallpaper\"; [ -s \"$f\" ] && sh \"$HOME/.config/quickshell/setwall.sh\" \"$(cat \"$f\")\""]
  }

  onShownChanged: {
    if (shown && !lister.running) lister.running = true
  }

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: win.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  implicitWidth: 630
  implicitHeight: card.height + 6
  color: "transparent"

  Item {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: win.open = false
  }

  Rectangle {
    id: card
    width: parent.width - 6
    height: col.implicitHeight + 28
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
      id: col
      x: 12
      y: 14
      width: parent.width - 24
      spacing: 10

      Item {
        width: col.width
        height: 20

        Text {
          anchors.left: parent.left
          anchors.leftMargin: 4
          anchors.verticalCenter: parent.verticalCenter
          text: Tr.t("Wallpaper")
          color: Colors.text
          font.family: win.fonte
          font.pixelSize: Math.round(14 * Settings.wScale)
          font.bold: true
        }

        Text {
          anchors.right: parent.right
          anchors.rightMargin: 4
          anchors.verticalCenter: parent.verticalCenter
          text: win.images.length + (win.images.length === 1 ? " imagem" : " imagens")
          color: Colors.textFaint
          font.family: win.fonte
          font.pixelSize: Math.round(11 * Settings.wScale)
        }
      }

      GridView {
        id: grid
        width: col.width
        height: Math.min(Math.ceil(win.images.length / 3), 3) * 124
        visible: win.images.length > 0
        cellWidth: Math.floor(col.width / 3)
        cellHeight: 124
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: win.images

        delegate: Item {
          width: grid.cellWidth
          height: grid.cellHeight

          Rectangle {
            anchors.fill: parent
            anchors.margins: 5
            radius: 8
            color: Colors.surface
            border.width: (modelData === win.current || ma.containsMouse) ? 2 : 1
            border.color: (modelData === win.current || ma.containsMouse) ? win.accent : Colors.border
            Behavior on border.color { ColorAnimation { duration: Math.round(200 * Settings.animMul) } }

            Image {
              anchors.fill: parent
              anchors.margins: 3
              source: "file://" + encodeURI(modelData)
              sourceSize.width: 400
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
              clip: true
            }

            Rectangle {
              visible: modelData === win.current
              anchors.top: parent.top
              anchors.right: parent.right
              anchors.margins: 8
              width: 22
              height: 22
              radius: 11
              color: win.accent

              Text {
                anchors.centerIn: parent
                text: Tr.t("󰄬")
                color: Colors.onAccent
                font.family: win.fonte
                font.pixelSize: Math.round(13 * Settings.wScale)
              }
            }

            Rectangle {
              visible: ma.containsMouse
              anchors.bottom: parent.bottom
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.margins: 3
              height: 22
              color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)

              Text {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                verticalAlignment: Text.AlignVCenter
                text: win.baseName(modelData)
                elide: Text.ElideRight
                color: Colors.text
                font.family: win.fonte
                font.pixelSize: Math.round(11 * Settings.wScale)
              }
            }

            MouseArea {
              id: ma
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: win.apply(modelData)
            }
          }
        }
      }

      Text {
        visible: win.images.length === 0
        width: col.width
        height: 48
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
        text: "Nenhuma imagem em " + win.dir
        color: Colors.textDim
        font.family: win.fonte
        font.pixelSize: Math.round(13 * Settings.wScale)
      }
    }
  }
}
