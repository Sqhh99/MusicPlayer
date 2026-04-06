import QtQuick
import MusicPlayer

Item {
    id: root

    property string iconSource: ""
    property int size: Theme.controlSize
    property int iconSize: Theme.iconSize
    property color backgroundColor: "transparent"
    property color hoverColor: "transparent"
    property color pressedColor: Theme.materialButtonPressedBg
    property color iconColor: Theme.textMuted
    property color activeColor: Theme.accent
    property bool active: false
    property bool showBorder: false
    property color borderColor: Theme.materialButtonBorder
    property color activeBackgroundColor: Theme.materialButtonActiveBg
    property real iconOpacity: 0.65
    property real activeOpacity: 0.95
    property int radius: Math.max(8, Math.round(size * 0.25))
    property bool hovered: mouseArea.containsMouse

    signal clicked()

    width: size
    height: size
    implicitWidth: size
    implicitHeight: size

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: root.active
            ? root.activeBackgroundColor
            : (mouseArea.pressed ? root.pressedColor
                                 : (mouseArea.containsMouse ? root.hoverColor : root.backgroundColor))
        border.color: root.showBorder ? root.borderColor : "transparent"
        border.width: root.showBorder ? 1 : 0
        
        // Scale effect on press only
        scale: mouseArea.pressed ? 0.92 : (mouseArea.containsMouse ? 1.05 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
    }

    Image {
        id: icon
        anchors.centerIn: parent
        source: root.iconSource
        width: root.iconSize
        height: root.iconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
        // Hover feedback via opacity change only
        opacity: root.active ? root.activeOpacity : (mouseArea.containsMouse ? Math.min(root.iconOpacity + 0.3, 1.0) : root.iconOpacity)
        scale: mouseArea.pressed ? 0.9 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 80 }
        }
        Behavior on scale {
            NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
