import QtQuick
import MusicPlayer
import QtQuick.Controls
import QtQuick.Layouts


Item {
    id: root

    property string songName: ""
    property bool isAlwaysOnTop: false

    signal minimizeClicked()
    signal closeClicked()
    signal alwaysOnTopClicked()
    signal dragStarted(point mousePos)
    signal dragMoved(point mouseGlobalPos)
    signal dragEnded()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.marginSmall
        anchors.rightMargin: Theme.marginNormal
        spacing: 0

        // Song name label
        Text {
            id: songLabel
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            
            text: root.songName || ""
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeNormal
            font.weight: Font.Medium
            elide: Text.ElideRight
            leftPadding: Theme.marginNormal
        }

        // Window control buttons
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: Theme.spacingNormal

            // Always on top button
            Button {
                id: alwaysOnTopBtn
                implicitWidth: Theme.buttonSizeSmall
                implicitHeight: Theme.buttonSizeSmall
                
                background: Rectangle {
                    color: "transparent"
                }
                
                contentItem: Image {
                    source: root.isAlwaysOnTop 
                        ? "qrc:/qt/qml/MusicPlayer/resources/icons/yizhiding.png" 
                        : "qrc:/qt/qml/MusicPlayer/resources/icons/zhiding.png"
                    sourceSize: Qt.size(Theme.iconSizeSmall, Theme.iconSizeSmall)
                    fillMode: Image.PreserveAspectFit
                }

                ToolTip.visible: hovered
                ToolTip.text: root.isAlwaysOnTop ? "取消置顶" : "置顶窗口"

                onClicked: root.alwaysOnTopClicked()
            }

            // Minimize button
            Button {
                id: minimizeBtn
                implicitWidth: Theme.buttonSizeSmall
                implicitHeight: Theme.buttonSizeSmall
                
                background: Rectangle {
                    color: "transparent"
                }
                
                contentItem: Image {
                    source: "qrc:/qt/qml/MusicPlayer/resources/icons/zuixiaohua.png"
                    sourceSize: Qt.size(Theme.iconSizeSmall, Theme.iconSizeSmall)
                    fillMode: Image.PreserveAspectFit
                }

                ToolTip.visible: hovered
                ToolTip.text: "最小化"

                onClicked: root.minimizeClicked()
            }

            // Close button
            Button {
                id: closeBtn
                implicitWidth: Theme.buttonSizeSmall
                implicitHeight: Theme.buttonSizeSmall
                
                background: Rectangle {
                    color: "transparent"
                }
                
                contentItem: Text {
                    text: "×"
                    color: closeBtn.hovered ? "#ff0000" : Theme.textLight
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                ToolTip.visible: hovered
                ToolTip.text: "关闭"

                onClicked: root.closeClicked()
            }
        }
    }

    // Mouse area for window dragging
    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: 80 // Don't drag over buttons
        
        onPressed: (mouse) => {
            root.dragStarted(Qt.point(mouse.x, mouse.y))
        }
        
        onPositionChanged: (mouse) => {
            if (pressed) {
                let globalPos = mapToGlobal(mouse.x, mouse.y)
                root.dragMoved(Qt.point(globalPos.x, globalPos.y))
            }
        }
        
        onReleased: root.dragEnded()
    }
}

