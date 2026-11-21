pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property bool dnd: false
    property var popupIds: []
    property var expiry: ({})
    property var total: ({})
    readonly property var popups: popupIds.filter(id => find(id) !== null).slice(0, Math.max(1, Settings.notifMax))
    readonly property var recent: srv.trackedNotifications.values.slice().reverse().slice(0, 6)

    function find(id) {
        const v = srv.trackedNotifications.values
        for (let i = 0; i < v.length; i++)
            if (v[i].id === id) return v[i]
        return null
    }
    function remaining(id) {
        const e = expiry[id]
        return e > 0 ? Math.max(1, e - Date.now()) : Settings.notifTimeout * 1000
    }
    function fraction(id) {
        const t = total[id]
        const e = expiry[id]
        if (!(t > 0) || !(e > 0)) return 1
        return Math.max(0, Math.min(1, (e - Date.now()) / t))
    }
    function hidePopup(id) {
        popupIds = popupIds.filter(x => x !== id)
    }
    function clearAll() {
        const v = srv.trackedNotifications.values.slice()
        for (let i = 0; i < v.length; i++) v[i].dismiss()
        popupIds = []
    }

    Timer {
        interval: 250
        repeat: true
        running: root.popupIds.length > 0
        onTriggered: {
            const now = Date.now()
            const keep = root.popupIds.filter(id => !(root.expiry[id] > 0 && root.expiry[id] <= now))
            if (keep.length !== root.popupIds.length) root.popupIds = keep
        }
    }

    NotificationServer {
        id: srv
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true
            if (root.dnd) return
            let ms = 0
            if (n.urgency !== NotificationUrgency.Critical) {
                const t = n.expireTimeout
                ms = Settings.notifTimeout * 1000
            }
            root.total[n.id] = ms
            root.expiry[n.id] = ms > 0 ? Date.now() + ms : 0
            root.popupIds = [n.id].concat(root.popupIds.filter(x => x !== n.id))
        }
    }
}
