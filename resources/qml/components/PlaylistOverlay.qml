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

    Item {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.headerHeight

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

        IconButton {
            id: closeButton
            size: 30
            iconSize: 12
            iconSource: Theme.iconPath + "x.png"
            iconOpacity: 0.6
            hoverColor: "#f3f4f6"
            pressedColor: "#e5e7eb"
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            z: 2
            onClicked: root.closeRequested()
        }

        MouseArea {
            id: dragArea
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: closeButton.width + closeButton.anchors.rightMargin + 8
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
                    mouse.accepted = true
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
