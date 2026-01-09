import QtQuick
import MusicPlayer

Item {
    id: root

    property real from: 0
    property real to: 100
    property real value: 0
    property bool showHandle: true
    property color trackColor: Theme.trackBg
    property color fillColor: Theme.trackFill
    property color handleColor: Theme.handle
    property int handleSize: 12
    property bool live: false
    property bool alwaysShowHandle: false

    signal seekRequested(real value)

    readonly property real range: Math.max(1, to - from)
    property bool dragging: false
    property real dragValue: value
    readonly property real visualValue: dragging ? dragValue : value
    readonly property real progress: Math.max(0, Math.min(1, (visualValue - from) / range))

    height: 10

    function valueFromPosition(posX) {
        var clamped = Math.max(0, Math.min(track.width, posX))
        return from + (clamped / track.width) * range
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.trackColor
    }

    Rectangle {
        anchors.left: track.left
        anchors.verticalCenter: track.verticalCenter
        height: track.height
        width: track.width * root.progress
        radius: track.radius
        color: root.fillColor
    }

    Rectangle {
        id: handle
        width: root.handleSize
        height: root.handleSize
        radius: root.handleSize / 2
        color: root.handleColor
        anchors.verticalCenter: track.verticalCenter
        x: (track.width * root.progress) - width / 2
        opacity: root.showHandle && (root.alwaysShowHandle || root.dragging || mouseArea.containsMouse) ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
        Behavior on x {
            NumberAnimation { duration: root.dragging ? 0 : 120 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            root.dragging = true
            root.dragValue = root.valueFromPosition(mouse.x)
            if (root.live) {
                root.seekRequested(root.dragValue)
            }
        }
        onPositionChanged: {
            if (pressed) {
                root.dragValue = root.valueFromPosition(mouse.x)
                if (root.live) {
                    root.seekRequested(root.dragValue)
                }
            }
        }
        onReleased: {
            if (root.dragging) {
                root.dragging = false
                root.seekRequested(root.dragValue)
            }
        }
    }
}
