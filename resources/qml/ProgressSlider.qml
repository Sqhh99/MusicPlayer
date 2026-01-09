import QtQuick
import MusicPlayer
import QtQuick.Controls


Slider {
    id: root

    property bool isDragging: false
    
    signal seekRequested(real position)

    height: 20
    
    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: Theme.sliderHeight
        radius: Theme.borderRadiusSmall / 2
        color: Theme.sliderTrack

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: Theme.accent
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.hovered || root.pressed ? Theme.sliderHandleSizeHover : Theme.sliderHandleSize
        height: width
        radius: width / 2
        color: root.pressed ? Theme.sliderHandleHover : (root.hovered ? Theme.sliderHandleHover : Theme.accent)
        
        Behavior on width {
            NumberAnimation { duration: Theme.animationDurationFast }
        }
        
        Behavior on color {
            ColorAnimation { duration: Theme.animationDurationFast }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.NoButton
    }

    onPressedChanged: {
        if (pressed) {
            isDragging = true
        } else {
            isDragging = false
            seekRequested(value)
        }
    }

    // Don't update value while dragging (handled by mouse)
    Binding {
        target: root
        property: "value"
        value: playerController.position
        when: !root.isDragging
    }
}

