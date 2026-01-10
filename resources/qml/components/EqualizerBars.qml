import QtQuick
import MusicPlayer

Item {
    id: root

    property bool playing: false
    property int barCount: Math.max(16, Math.round(width / 12))
    property int barSpacing: 3
    readonly property real barWidth: Math.max(3, (width - (barSpacing * (barCount - 1))) / barCount)
    property color barColor: Theme.textPrimary

    height: 24

    // Faster timer for more responsive animation
    Timer {
        id: pulseTimer
        interval: 100 + Math.random() * 50  // 100-150ms for more natural feel
        repeat: true
        running: root.playing
        onTriggered: {
            interval = 80 + Math.random() * 70  // Vary timing for organic feel
            for (var i = 0; i < barsRepeater.count; i += 1) {
                var item = barsRepeater.itemAt(i)
                if (item) {
                    // More dynamic range based on position
                    var baseHeight = 4 + Math.random() * (root.height - 4)
                    // Add wave effect - bars near center tend to be taller
                    var centerFactor = 1 - Math.abs(i - barCount / 2) / (barCount / 2) * 0.3
                    item.targetHeight = baseHeight * centerFactor + 2
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
                height: 8 + Math.random() * 8  // Random initial heights
                radius: Math.max(1.5, root.barWidth * 0.3)
                color: root.barColor
                opacity: 0.7 + Math.random() * 0.3

                property real targetHeight: height
                onTargetHeightChanged: height = targetHeight

                Behavior on height {
                    NumberAnimation { 
                        duration: 120 + Math.random() * 60
                        easing.type: Easing.OutQuad 
                    }
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
