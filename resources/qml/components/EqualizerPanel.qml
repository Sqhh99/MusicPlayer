import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import MusicPlayer

Rectangle {
    id: root

    property int bass: 50
    property int mid: 50
    property int treble: 50

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

                Slider {
                    id: bassSlider
                    Layout.fillHeight: true
                    Layout.preferredHeight: 96
                    from: 0
                    to: 100
                    value: root.bass
                    orientation: Qt.Vertical
                    onValueChanged: {
                        if (pressed) {
                            root.bassRequested(Math.round(value))
                        }
                    }
                    background: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: Theme.trackBg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    handle: Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.trackFill
                    }
                }

                Text {
                    text: "低音"
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                spacing: 6

                Slider {
                    id: midSlider
                    Layout.fillHeight: true
                    Layout.preferredHeight: 96
                    from: 0
                    to: 100
                    value: root.mid
                    orientation: Qt.Vertical
                    onValueChanged: {
                        if (pressed) {
                            root.midRequested(Math.round(value))
                        }
                    }
                    background: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: Theme.trackBg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    handle: Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.trackFill
                    }
                }

                Text {
                    text: "中音"
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }

            ColumnLayout {
                Layout.fillHeight: true
                spacing: 6

                Slider {
                    id: trebleSlider
                    Layout.fillHeight: true
                    Layout.preferredHeight: 96
                    from: 0
                    to: 100
                    value: root.treble
                    orientation: Qt.Vertical
                    onValueChanged: {
                        if (pressed) {
                            root.trebleRequested(Math.round(value))
                        }
                    }
                    background: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: Theme.trackBg
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    handle: Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.trackFill
                    }
                }

                Text {
                    text: "高音"
                    font.pixelSize: 10
                    font.family: Theme.fontFamily
                    color: Theme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }
        }
    }
}
