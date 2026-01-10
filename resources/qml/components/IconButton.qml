import QtQuick
import MusicPlayer

Item {
    id: root

    property string iconSource: ""
    property int size: Theme.controlSize
    property int iconSize: Theme.iconSize
    property color backgroundColor: "transparent"
    property color hoverColor: Theme.hoverBg
    property color pressedColor: "#00000012"
    property color iconColor: Theme.textMuted
    property color activeColor: Theme.accent
    property bool active: false
    property bool showBorder: false
    property color borderColor: Theme.cardBorder
    property color activeBackgroundColor: Theme.accentSoft
    property real iconOpacity: 0.65
    property real activeOpacity: 0.95
    property int radius: Math.max(8, Math.round(size * 0.25))
    property bool hovered: false

    signal clicked()

    width: size
    height: size
    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.active
            ? root.activeBackgroundColor
            : (mouseArea.pressed
                ? root.pressedColor
                : (mouseArea.containsMouse ? root.hoverColor : root.backgroundColor))
        border.color: root.showBorder ? root.borderColor : "transparent"
        border.width: root.showBorder ? 1 : 0
    }

    Image {
        anchors.centerIn: parent
        source: root.iconSource
        width: root.iconSize
        height: root.iconSize
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.active ? root.activeOpacity : root.iconOpacity
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onCanceled: root.hovered = false
        onClicked: root.clicked()
    }
}
