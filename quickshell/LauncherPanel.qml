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
    target: "launcher"
    function toggle(): void {
      if (!win.open && Date.now() - win.closedAt < 400) return
      win.open = !win.open
    }
  }

  property bool open: false
  property bool shown: open
  property color accent: Colors.accent
  property string fonte: Settings.wFontFamily
  property string query: ""
  property var results: []
  property int selected: 0
  readonly property bool mini: Settings.launcherMode === "minimal"
  readonly property int mStart: Math.max(0, Math.min(selected - 3, results.length - 7))
  readonly property string lpos: Settings.launcherPos

  function filter() {
    const q = query.trim().toLowerCase()
    const all = DesktopEntries.applications.values
    const scored = []
    for (let i = 0; i < all.length; i++) {
      const e = all[i]
      if (e.noDisplay) continue
      const name = (e.name || "").toLowerCase()
      let score = -1
      if (q === "") score = 0
      else if (name.startsWith(q)) score = 0
      else if (name.indexOf(q) >= 0) score = 1
      else if (((e.genericName || "") + " " + (e.comment || "")).toLowerCase().indexOf(q) >= 0) score = 2
      if (score >= 0) scored.push({ e: e, s: score, n: name })
    }
    scored.sort((a, b) => (a.s - b.s) || a.n.localeCompare(b.n))
    results = scored.map(x => x.e)
  }

  property string terminal: "kitty"

  function launch(entry) {
    if (!entry) return
    if (entry.runInTerminal) {
      const job = { command: [win.terminal].concat(entry.command) }
      if (entry.workingDirectory) job.workingDirectory = entry.workingDirectory
      Quickshell.execDetached(job)
    } else {
      entry.execute()
    }
    win.open = false
  }

  onShownChanged: {
    if (shown) {
      input.text = ""
      query = ""
      selected = 0
      filter()
      Qt.callLater(() => input.forceActiveFocus())
    }
  }

  Connections {
    target: win
    function onSelectedChanged() {
      appList.positionViewAtIndex(win.selected, ListView.Contain)
    }
  }

  visible: shown || card.opacity > 0.01

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: win.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore


  implicitWidth: mini ? 820 : 560
  anchors {
    top: lpos === "top"
    bottom: lpos === "bottom"
    left: lpos === "left"
    right: lpos === "right"
  }
  margins {
    top: 110
    bottom: 90
    left: 80
    right: 80
  }
  implicitHeight: card.height + 6
  color: "transparent"

  Rectangle {
    id: card
    width: parent.width
    height: win.mini ? 158 : col.implicitHeight + 24
    radius: Settings.wRadius
    color: win.mini ? "transparent" : Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
    border.color: Colors.border
    border.width: win.mini ? 0 : Settings.wBorder

    opacity: win.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Math.round(450 * Settings.animMul); easing.type: Easing.OutCubic } }

    transform: Translate {
      y: win.shown ? 0 : -28
      Behavior on y { NumberAnimation { duration: Math.round(450 * Settings.animMul); easing.type: Easing.OutCubic } }
    }

    Column {
      id: col
      x: win.mini ? (parent.width - width) / 2 : 12
      y: win.mini ? 0 : 12
      width: win.mini ? 360 : parent.width - 24
      spacing: 8

      // ---------- busca ----------
      Rectangle {
        width: col.width
        height: 44
        radius: win.mini ? Math.min(Settings.wRadius, 22) : 8
        color: win.mini ? Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity) : Colors.surface
        border.color: win.accent
        border.width: Settings.wBorder

        Text {
          id: searchIcon
          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          text: Tr.t("󰍉")
          color: win.accent
          font.family: win.fonte
          font.pixelSize: Math.round(18 * Settings.wScale)
        }

        TextInput {
          id: input
          anchors.left: searchIcon.right
          anchors.leftMargin: 10
          anchors.right: parent.right
          anchors.rightMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          color: Colors.text
          selectionColor: win.accent
          selectedTextColor: Colors.onAccent
          font.family: win.fonte
          font.pixelSize: Math.round(15 * Settings.wScale)
          clip: true
          focus: true

          onTextChanged: {
            win.query = text
            win.selected = 0
            win.filter()
            appList.positionViewAtBeginning()
          }

          Keys.onEscapePressed: win.open = false
          Keys.onDownPressed: win.selected = Math.min(win.results.length - 1, win.selected + 1)
          Keys.onTabPressed: win.selected = Math.min(win.results.length - 1, win.selected + 1)
          Keys.onUpPressed: win.selected = Math.max(0, win.selected - 1)
          Keys.onReturnPressed: win.launch(win.results[win.selected])
          Keys.onEnterPressed: win.launch(win.results[win.selected])
          Keys.onRightPressed: event => { if (win.mini && input.cursorPosition === input.text.length) win.selected = Math.min(win.results.length - 1, win.selected + 1); else event.accepted = false }
          Keys.onLeftPressed: event => { if (win.mini && input.cursorPosition === 0) win.selected = Math.max(0, win.selected - 1); else event.accepted = false }

          Text {
            visible: input.text === ""
            text: Tr.t("Buscar aplicativos...")
            color: Colors.textFaint
            font.family: win.fonte
            font.pixelSize: Math.round(15 * Settings.wScale)
          }
        }
      }

      // ---------- lista ----------
      ListView {
        id: appList
        width: col.width
        height: Math.min(win.results.length, 8) * 40
        visible: win.results.length > 0 && !win.mini
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: win.results

        delegate: Rectangle {
          width: appList.width
          height: 40
          radius: 8
          color: index === win.selected ? win.accent : "transparent"
          Behavior on color { ColorAnimation { duration: Math.round(150 * Settings.animMul) } }

          Image {
            id: ico
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectFit
            source: Quickshell.iconPath(modelData.icon, "application-x-executable")
          }

          Text {
            id: sub
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 170)
            text: modelData.genericName || ""
            elide: Text.ElideRight
            color: index === win.selected ? Colors.onAccentDim : Colors.textFaint
            font.family: win.fonte
            font.pixelSize: Math.round(11 * Settings.wScale)
          }

          Text {
            anchors.left: ico.right
            anchors.leftMargin: 12
            anchors.right: sub.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.name
            elide: Text.ElideRight
            color: index === win.selected ? Colors.onAccent : Colors.text
            font.family: win.fonte
            font.pixelSize: Math.round(13 * Settings.wScale)
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPositionChanged: win.selected = index
            onClicked: win.launch(modelData)
          }
        }
      }

      Text {
        visible: win.results.length === 0 && !win.mini
        width: col.width
        height: 32
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Tr.t("Nenhum aplicativo encontrado")
        color: Colors.textDim
        font.family: win.fonte
        font.pixelSize: Math.round(13 * Settings.wScale)
      }
    }

    Rectangle {
      id: miniBox
      visible: win.mini
      x: 0
      y: 54
      width: parent.width
      height: 104
      radius: Settings.wRadius
      color: Qt.rgba(Colors.card.r, Colors.card.g, Colors.card.b, Settings.uiOpacity)
      border.color: Colors.border
      border.width: Settings.wBorder

      ListView {
        id: miniList
        anchors.fill: parent
        anchors.margins: 10
        anchors.bottomMargin: 14
        orientation: ListView.Horizontal
        spacing: 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: win.mini ? win.results : []
        currentIndex: win.selected
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        WheelHandler {
          acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
          onWheel: event => {
            const dx = event.angleDelta.x !== 0 ? event.angleDelta.x : event.angleDelta.y
            miniList.contentX = Math.max(0, Math.min(Math.max(0, miniList.contentWidth - miniList.width), miniList.contentX - dx))
          }
        }

        delegate: Rectangle {
          id: tile
          required property var modelData
          required property int index
          readonly property bool sel: index === win.selected
          width: 80
          height: ListView.view.height
          radius: Math.min(Settings.wRadius, 14)
          color: sel ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.30)
               : (tma.containsMouse ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.14) : "transparent")
          border.width: sel ? 1 : 0
          border.color: win.accent
          Behavior on color { ColorAnimation { duration: Math.round(120 * Settings.animMul) } }

          Image {
            id: tIco
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            width: 36
            height: 36
            sourceSize.width: 72
            sourceSize.height: 72
            fillMode: Image.PreserveAspectFit
            source: Quickshell.iconPath(tile.modelData.icon, "application-x-executable")
          }
          Text {
            anchors.top: tIco.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 8
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: tile.modelData.name
            color: tile.sel ? Colors.text : Colors.textDim
            font.family: win.fonte
            font.pixelSize: Math.round(11 * Settings.wScale)
          }
          MouseArea {
            id: tma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: win.launch(tile.modelData)
          }
        }
      }

      // indicador de posicao da rolagem
      Rectangle {
        visible: miniList.contentWidth > miniList.width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        height: 3
        radius: 2
        color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.55)
        x: 10 + (miniList.contentX / miniList.contentWidth) * (parent.width - 20)
        width: (miniList.width / miniList.contentWidth) * (parent.width - 20)
      }

      Text {
        visible: win.results.length === 0
        anchors.centerIn: parent
        text: Tr.t("Nenhum aplicativo encontrado")
        color: Colors.textDim
        font.family: win.fonte
        font.pixelSize: Math.round(13 * Settings.wScale)
      }
    }
  }
}
