import QtQuick
import MusicPlayer
import "./"

Item {
    id: root

    property var controller
    signal openMiniRequested()

    readonly property bool playing: root.controller ? root.controller.isPlaying : false
    property int activeWaveIndex: 0
    property int waveDirection: 1

    function heightForIndex(index) {
        if (!root.playing) {
            return Theme.islandWaveIdleHeight
        }
        var distance = Math.abs(index - root.activeWaveIndex)
        if (distance === 0) {
            return Theme.islandWavePeakHeight
        }
        if (distance === 1) {
            return Theme.islandWaveMidHeight
        }
        return Theme.islandWaveIdleHeight
    }

    function syncWaveHeights() {
        for (var i = 0; i < barsRepeater.count; i += 1) {
            var bar = barsRepeater.itemAt(i)
            if (!bar) {
                continue
            }
            bar.targetHeight = root.heightForIndex(i)
        }
    }

    function advanceWave() {
        if (!root.playing) {
            root.activeWaveIndex = 0
            root.waveDirection = 1
            return
        }

        if (root.activeWaveIndex === Theme.islandWaveBarCount - 1) {
            root.waveDirection = -1
        } else if (root.activeWaveIndex === 0) {
            root.waveDirection = 1
        }

        root.activeWaveIndex += root.waveDirection
    }

    onPlayingChanged: {
        root.activeWaveIndex = 0
        root.waveDirection = 1
        root.syncWaveHeights()
    }
    onActiveWaveIndexChanged: syncWaveHeights()

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openMiniRequested()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusIsland
        color: "transparent"
        border.width: 0

        Rectangle {
            width: 44
            height: 44
            radius: 22
            anchors.left: parent.left
            anchors.leftMargin: 0
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"

            AlbumArt {
                anchors.centerIn: parent
                size: Theme.islandCoverSize
                cornerRadius: 13
                title: root.controller ? root.controller.currentSong : ""
                playing: root.playing
                source: root.controller ? root.controller.albumArtUrl : ""
            }
        }

        Item {
            id: waveform
            width: Theme.islandWaveBubbleWidth
            height: Theme.islandWaveBubbleHeight
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Theme.islandWaveBg
                border.width: 0
            }

            Timer {
                id: pulseTimer
                interval: 120
                repeat: true
                running: root.playing
                onTriggered: root.advanceWave()
            }

            Row {
                anchors.centerIn: parent
                spacing: Theme.islandWaveGap

                Repeater {
                    id: barsRepeater
                    model: Theme.islandWaveBarCount

                    Rectangle {
                        id: bar
                        width: Theme.islandWaveBarWidth
                        height: root.heightForIndex(index)
                        radius: height / 2
                        color: Theme.islandWaveColor
                        antialiasing: true
                        layer.enabled: true
                        layer.smooth: true

                        property real targetHeight: height

                        onTargetHeightChanged: {
                            height = targetHeight
                        }

                        Behavior on height {
                            NumberAnimation { duration: 140; easing.type: Easing.InOutQuad }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: Theme.islandWaveGlowColor
                            scale: 1.45
                            opacity: root.playing ? 0.9 : 0.35
                            z: -1
                        }
                    }
                }
            }

            Component.onCompleted: root.syncWaveHeights()
        }
    }
}
