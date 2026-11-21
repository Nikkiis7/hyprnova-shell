import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root
    property string lastKey: ""

    readonly property var sp: {
        const ps = Mpris.players.values
        for (let i = 0; i < ps.length; i++) {
            const id = ((ps[i].identity || "") + " " + (ps[i].desktopEntry || "")).toLowerCase()
            if (id.indexOf("spotify") >= 0) return ps[i]
        }
        return null
    }
    readonly property string title: sp ? (sp.trackTitle || "") : ""
    readonly property string artist: sp ? (sp.trackArtist || "") : ""
    readonly property string art: sp ? (sp.trackArtUrl || "") : ""
    readonly property bool playing: sp !== null && sp.playbackState === MprisPlaybackState.Playing

    onTitleChanged: debounce.restart()
    onArtistChanged: debounce.restart()
    onPlayingChanged: debounce.restart()

    Timer {
        id: debounce
        interval: 700
        onTriggered: root.notify()
    }

    function notify() {
        if (!root.playing || root.title === "") return
        const key = root.title + "|" + root.artist
        if (key === root.lastKey) return
        root.lastKey = key
        sender.command = ["sh", "-c",
            'url="$1"; img=""; ' +
            'if [ -n "$url" ]; then f="/tmp/qs-art-$(printf %s "$url" | md5sum | cut -c1-12).jpg"; ' +
            '[ -s "$f" ] || curl -fsL --max-time 5 -o "$f" "$url" || rm -f "$f"; [ -s "$f" ] && img="$f"; fi; ' +
            'if [ -n "$img" ]; then exec notify-send -a Spotify -t 5000 -h string:image-path:"$img" "$2" "$3"; ' +
            'else exec notify-send -a Spotify -t 5000 -i spotify "$2" "$3"; fi',
            "sh", root.art, root.title, root.artist]
        sender.running = true
    }

    Process { id: sender }
}
