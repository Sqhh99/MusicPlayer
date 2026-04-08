import QtQuick
import QtQuick.Window
import MusicPlayer

Item {
    id: root

    property var appWindow
    property bool isMiniMode: false
    property bool isIslandMode: false
    property bool showPlaylist: false
    property bool showEq: false
    property bool showSettings: false
    property int snapThreshold: 20

    visible: !root.isIslandMode && !root.showPlaylist && !root.showEq && !root.showSettings
    height: Theme.dragHeight
    z: 1

    property point dragStartPosition
    property bool isDragging: false

    function snapToEdge(newX, newY) {
        var screenWidth = Screen.width
        var screenHeight = Screen.height
        var windowWidth = root.appWindow ? root.appWindow.width : 0
        var windowHeight = root.appWindow ? root.appWindow.height : 0

        if (newX < snapThreshold) {
            newX = 0
        } else if (newX + windowWidth > screenWidth - snapThreshold) {
            newX = screenWidth - windowWidth
        }

        if (newY < snapThreshold) {
            newY = 0
        } else if (newY + windowHeight > screenHeight - snapThreshold - 40) {
            newY = screenHeight - windowHeight - 40
        }

        return Qt.point(newX, newY)
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.SizeAllCursor
        onPressed: (mouse) => {
            if (!root.appWindow) {
                return
            }
            root.isDragging = true
            root.dragStartPosition = Qt.point(mouse.x, mouse.y)
        }
        onPositionChanged: (mouse) => {
            if (!root.appWindow) {
                return
            }
            if (pressed && root.isDragging) {
                var globalPos = mapToGlobal(mouse.x, mouse.y)
                var newX = globalPos.x - root.dragStartPosition.x
                var newY = globalPos.y - root.dragStartPosition.y

                if (root.isMiniMode) {
                    var snapped = root.snapToEdge(newX, newY)
                    root.appWindow.x = snapped.x
                    root.appWindow.y = snapped.y
                } else {
                    root.appWindow.x = newX
                    root.appWindow.y = newY
                }
            }
        }
        onReleased: root.isDragging = false
    }
}
