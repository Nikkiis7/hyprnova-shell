import QtQuick

Item {
    default property alias content: row.data
    height: parent ? parent.height : 36
    implicitWidth: row.implicitWidth

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
    }
}
