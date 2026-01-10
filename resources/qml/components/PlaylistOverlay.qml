import QtQuick
import QtQuick.Layouts
import MusicPlayer
import "./"

Rectangle {
    id: root

    property bool open: false
    property var model
    property int currentIndex: -1
    property bool isPlaying: false
    property var appWindow: null

    signal closeRequested()
    signal openFilesRequested()
    signal selectIndex(int index)

    visible: open || opacity > 0
    opacity: open ? 1 : 0
    x: open ? 0 : width

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: parent.width
    radius: Theme.radiusLarge
    color: Theme.overlayBg
    border.color: Theme.overlayBorder
    border.width: 1
    clip: true
    z: 4

    Behavior on opacity {
        NumberAnimation { duration: 240 }
    }
    Behavior on x {
        NumberAnimation { duration: 320; easing.type: Easing.InOutQuad }
    }

    property int headerHeight: 64
    property point dragStartPos: Qt.point(0, 0)
    property bool dragging: false

    // Header area
    Rectangle {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerHeight
        color: "transparent"

        Text {
            id: headerTitle
            text: "播放列表"
            font.pixelSize: 16
            font.family: Theme.fontFamily
            font.weight: Font.DemiBold
            color: Theme.textPrimary
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
        }

        // Close button - using separate MouseArea with containsMouse
        Rectangle {
            id: closeButton
            width: 30
            height: 30
            radius: 8
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            color: closeButtonArea.pressed ? "#e5e7eb" : (closeButtonArea.containsMouse ? "#f3f4f6" : "transparent")
            z: 10

            Image {
                anchors.centerIn: parent
                source: Theme.iconPath + "x.png"
                width: 12
                height: 12
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: closeButtonArea.containsMouse ? 0.9 : 0.6
            }

            MouseArea {
                id: closeButtonArea
                anchors.fill: parent
                anchors.margins: -5  // Extend hit area slightly
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                
                onClicked: {
                    root.closeRequested()
                }
            }
        }

        // Drag area - explicitly sized to not overlap close button
        MouseArea {
            id: dragArea
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width - closeButton.width - 40  // Leave space
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            z: 1
            
            onPressed: (mouse) => {
                if (mouse.button !== Qt.LeftButton) {
                    return
                }
                if (root.appWindow) {
                    root.dragging = true
                    root.dragStartPos = Qt.point(mouse.x, mouse.y)
                }
            }
            onPositionChanged: (mouse) => {
                if (root.dragging && root.appWindow) {
                    var globalPos = mapToGlobal(mouse.x, mouse.y)
                    root.appWindow.x = globalPos.x - root.dragStartPos.x
                    root.appWindow.y = globalPos.y - root.dragStartPos.y
                }
            }
            onReleased: root.dragging = false
            onCanceled: root.dragging = false
        }
    }

    Rectangle {
        id: headerDivider
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        height: 1
        color: Theme.overlayBorder
    }

    ListView {
        id: listView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headerDivider.bottom
        anchors.bottom: parent.bottom
        clip: true
        spacing: 6
        model: root.model
        boundsBehavior: Flickable.StopAtBounds
        interactive: true
        leftMargin: 16
        rightMargin: 16
        topMargin: 16
        bottomMargin: 16

        delegate: Item {
            id: rowItem
            width: listView.width - 32
            height: 54
            property bool hovered: false

            Rectangle {
                anchors.fill: parent
                radius: 14
                color: root.currentIndex === itemIndex
                    ? "#eff6ff"
                    : (rowItem.hovered ? "#f9fafb" : "transparent")
                opacity: root.currentIndex === itemIndex ? 0.5 : 1
                border.color: "transparent"
                border.width: 0
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: fileName
                        font.pixelSize: 13
                        font.family: Theme.fontFamily
                        font.weight: Font.DemiBold
                        color: (root.currentIndex === itemIndex) ? Theme.accentDark : Theme.textSecondary
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "本地音乐"
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                        color: Theme.textSubtle
                        elide: Text.ElideRight
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: durationText
                    font.pixelSize: 11
                    font.family: Theme.fontFamilyMono
                    color: Theme.textMuted
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: rowItem.hovered = true
                onExited: rowItem.hovered = false
                onClicked: root.selectIndex(itemIndex)
            }
        }
    }
}
