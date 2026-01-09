import QtQuick
import MusicPlayer

Item {
    id: root

    property bool playing: false
    property int barCount: Math.max(20, Math.round(width / 10))
    property int barSpacing: 3
    readonly property real barWidth: Math.max(2, (width - (barSpacing * (barCount - 1))) / barCount)
    property color barColor: Theme.textPrimary

    height: 24

    Timer {
        id: pulseTimer
        interval: 320
        repeat: true
        running: root.playing
        onTriggered: {
            for (var i = 0; i < barsRepeater.count; i += 1) {
                var item = barsRepeater.itemAt(i)
                if (item) {
                    item.targetHeight = Math.max(6, Math.random() * root.height)
                }
            }
        }
    }

    Row {
        id: barsRow
        anchors.fill: parent
        anchors.margins: 0
        spacing: root.barSpacing
        visible: root.playing

        Repeater {
            id: barsRepeater
            model: root.barCount

            Rectangle {
                id: bar
                width: root.barWidth
                height: 12
                radius: 2
                color: root.barColor
                opacity: 0.75

                property real targetHeight: height
                onTargetHeightChanged: height = targetHeight

                Behavior on height {
                    NumberAnimation { duration: 380; easing.type: Easing.InOutQuad }
                }

                anchors.bottom: parent.bottom
            }
        }
    }

    Rectangle {
        id: idleTrack
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 3
        radius: 2
        color: Theme.trackBg
        visible: !root.playing
        clip: true

        Rectangle {
            id: shimmer
            width: idleTrack.width * 0.4
            height: idleTrack.height
            x: -width
            radius: 3
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#00000000" }
                GradientStop { position: 0.5; color: "#cbd5f533" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { from: -width; to: idleTrack.width; duration: 2600; easing.type: Easing.InOutQuad }
            }
        }
    }
}
