import QtQuick
import MusicPlayer
import QtQuick.Controls
import QtQuick.Layouts


Popup {
    id: root
    
    width: 50
    height: 150
    padding: 10
    
    modal: false
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    background: Rectangle {
        color: Theme.background
        radius: Theme.borderRadius
        border.color: Theme.border
        border.width: 1
    }
    
    contentItem: ColumnLayout {
        spacing: Theme.spacingSmall
        
        // Volume percentage label
        Text {
            id: percentLabel
            Layout.alignment: Qt.AlignHCenter
            text: playerController.volume + "%"
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
        }
        
        // Vertical volume slider
        Slider {
            id: volumeSlider
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignHCenter
            
            orientation: Qt.Vertical
            from: 0
            to: 100
            value: playerController.volume
            stepSize: 1
            
            background: Rectangle {
                x: volumeSlider.leftPadding + volumeSlider.availableWidth / 2 - width / 2
                y: volumeSlider.topPadding
                width: Theme.sliderHeight
                height: volumeSlider.availableHeight
                radius: Theme.borderRadiusSmall / 2
                color: Theme.sliderTrack
                
                Rectangle {
                    width: parent.width
                    height: volumeSlider.visualPosition * parent.height
                    y: parent.height - height
                    radius: parent.radius
                    color: Theme.accent
                }
            }
            
            handle: Rectangle {
                x: volumeSlider.leftPadding + volumeSlider.availableWidth / 2 - width / 2
                y: volumeSlider.topPadding + volumeSlider.visualPosition * (volumeSlider.availableHeight - height)
                width: volumeSlider.hovered || volumeSlider.pressed ? Theme.sliderHandleSizeHover : Theme.sliderHandleSize
                height: width
                radius: width / 2
                color: volumeSlider.pressed ? Theme.sliderHandleHover : Theme.accent
                
                Behavior on width {
                    NumberAnimation { duration: Theme.animationDurationFast }
                }
            }
            
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.NoButton
            }
            
            onMoved: {
                playerController.setVolume(value)
            }
        }
    }
    
    // Update slider when volume changes externally
    Connections {
        target: playerController
        function onVolumeChanged() {
            if (!volumeSlider.pressed) {
                volumeSlider.value = playerController.volume
            }
        }
    }
}

