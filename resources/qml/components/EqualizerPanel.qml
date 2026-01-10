import QtQuick
import QtQuick.Layouts
import MusicPlayer

Rectangle {
    id: root

    property int bass: 50
    property int mid: 50
    property int treble: 50
    property int bassValue: bass
    property int midValue: mid
    property int trebleValue: treble

    signal bassRequested(int value)
    signal midRequested(int value)
    signal trebleRequested(int value)

    width: 240
    height: 160
    radius: 18
    color: Theme.cardBg
    border.color: Theme.cardBorder
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        Text {
            text: "均衡器"
            font.pixelSize: 12
            font.family: Theme.fontFamily
            font.weight: Font.DemiBold
            color: Theme.textPrimary
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            ColumnLayout {
                Layout.fillHeight: true
                spacing: 6

                Item {
                    id: bassSlider
                    Layout.preferredHeight: 96
                    Layout.preferredWidth: 24
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        id: bassTrack
                        width: 6
                        height: parent.height
                        radius: 3
                        color: Theme.trackBg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        id: bassHandle
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.trackFill
                        anchors.horizontalCenter: bassTrack.horizontalCenter
                        y: bassTrack.y + (1 - (root.bassValue / 100)) * (bassTrack.height - height)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => {
                            updateBass(mouse.y)
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                updateBass(mouse.y)
                            }
                        }
                        function updateBass(yPos) {
                            var range = bassTrack.height - bassHandle.height
                            if (range <= 0) {
                                return
                            }
                            var clamped = Math.max(0, Math.min(range, yPos - bassHandle.height / 2))
                            var value = Math.round((1 - (clamped / range)) * 100)
                            if (root.bassValue !== value) {
                                root.bassValue = value
                                root.bassRequested(value)
                            }
                        }
                    }
                }

                Text {
                    text: "低音"
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                spacing: 6

                Item {
                    id: midSlider
                    Layout.preferredHeight: 96
                    Layout.preferredWidth: 24
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        id: midTrack
                        width: 6
                        height: parent.height
                        radius: 3
                        color: Theme.trackBg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        id: midHandle
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.trackFill
                        anchors.horizontalCenter: midTrack.horizontalCenter
                        y: midTrack.y + (1 - (root.midValue / 100)) * (midTrack.height - height)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => {
                            updateMid(mouse.y)
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                updateMid(mouse.y)
                            }
                        }
                        function updateMid(yPos) {
                            var range = midTrack.height - midHandle.height
                            if (range <= 0) {
                                return
                            }
                            var clamped = Math.max(0, Math.min(range, yPos - midHandle.height / 2))
                            var value = Math.round((1 - (clamped / range)) * 100)
                            if (root.midValue !== value) {
                                root.midValue = value
                                root.midRequested(value)
                            }
                        }
                    }
                }

                Text {
                    text: "中音"
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                spacing: 6

                Item {
                    id: trebleSlider
                    Layout.preferredHeight: 96
                    Layout.preferredWidth: 24
                    Layout.alignment: Qt.AlignHCenter

                    Rectangle {
                        id: trebleTrack
                        width: 6
                        height: parent.height
                        radius: 3
                        color: Theme.trackBg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        id: trebleHandle
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.trackFill
                        anchors.horizontalCenter: trebleTrack.horizontalCenter
                        y: trebleTrack.y + (1 - (root.trebleValue / 100)) * (trebleTrack.height - height)
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => {
                            updateTreble(mouse.y)
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                updateTreble(mouse.y)
                            }
                        }
                        function updateTreble(yPos) {
                            var range = trebleTrack.height - trebleHandle.height
                            if (range <= 0) {
                                return
                            }
                            var clamped = Math.max(0, Math.min(range, yPos - trebleHandle.height / 2))
                            var value = Math.round((1 - (clamped / range)) * 100)
                            if (root.trebleValue !== value) {
                                root.trebleValue = value
                                root.trebleRequested(value)
                            }
                        }
                    }
                }

                Text {
                    text: "高音"
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    onBassChanged: root.bassValue = bass
    onMidChanged: root.midValue = mid
    onTrebleChanged: root.trebleValue = treble
}
