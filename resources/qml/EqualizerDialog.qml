import QtQuick
import MusicPlayer
import QtQuick.Controls
import QtQuick.Layouts


Dialog {
    id: root
    
    title: "均衡器"
    modal: true
    standardButtons: Dialog.Ok
    
    width: 300
    height: 280
    
    background: Rectangle {
        color: Theme.background
        radius: Theme.borderRadius
        border.color: Theme.border
        border.width: 1
    }
    
    header: Rectangle {
        height: 40
        color: Theme.transparent
        
        Text {
            anchors.centerIn: parent
            text: root.title
            color: Theme.textPrimary
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
        }
    }
    
    contentItem: ColumnLayout {
        spacing: Theme.spacingLarge
        
        // Preset selector
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingNormal
            
            Text {
                text: "预设:"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeNormal
            }
            
            ComboBox {
                id: presetCombo
                Layout.fillWidth: true
                
                model: ["平坦", "低音增强", "高音增强", "人声增强", "摇滚", "流行", "古典", "爵士", "自定义"]
                currentIndex: playerController.equalizerPreset
                
                // Use onActivated to avoid binding loop (only fires on user interaction)
                onActivated: {
                    playerController.equalizerPreset = currentIndex
                }
                
                background: Rectangle {
                    implicitWidth: 120
                    implicitHeight: 30
                    color: Theme.white
                    border.color: Theme.border
                    border.width: 1
                    radius: Theme.borderRadiusSmall
                }
            }
        }
        
        // Bass slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "低音"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    id: bassValueLabel
                    text: playerController.bassLevel
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
            
            Slider {
                id: bassSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: playerController.bassLevel
                stepSize: 1
                
                onMoved: {
                    playerController.bassLevel = value
                    presetCombo.currentIndex = 8 // Custom
                }
                
                background: Rectangle {
                    x: bassSlider.leftPadding
                    y: bassSlider.topPadding + bassSlider.availableHeight / 2 - height / 2
                    width: bassSlider.availableWidth
                    height: Theme.sliderHeight
                    radius: 2
                    color: Theme.sliderTrack
                    
                    Rectangle {
                        width: bassSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                }
                
                handle: Rectangle {
                    x: bassSlider.leftPadding + bassSlider.visualPosition * (bassSlider.availableWidth - width)
                    y: bassSlider.topPadding + bassSlider.availableHeight / 2 - height / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.accent
                }
            }
        }
        
        // Mid slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "中音"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: playerController.midLevel
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
            
            Slider {
                id: midSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: playerController.midLevel
                stepSize: 1
                
                onMoved: {
                    playerController.midLevel = value
                    presetCombo.currentIndex = 8
                }
                
                background: Rectangle {
                    x: midSlider.leftPadding
                    y: midSlider.topPadding + midSlider.availableHeight / 2 - height / 2
                    width: midSlider.availableWidth
                    height: Theme.sliderHeight
                    radius: 2
                    color: Theme.sliderTrack
                    
                    Rectangle {
                        width: midSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                }
                
                handle: Rectangle {
                    x: midSlider.leftPadding + midSlider.visualPosition * (midSlider.availableWidth - width)
                    y: midSlider.topPadding + midSlider.availableHeight / 2 - height / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.accent
                }
            }
        }
        
        // Treble slider
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "高音"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSmall
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: playerController.trebleLevel
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
            
            Slider {
                id: trebleSlider
                Layout.fillWidth: true
                from: 0
                to: 100
                value: playerController.trebleLevel
                stepSize: 1
                
                onMoved: {
                    playerController.trebleLevel = value
                    presetCombo.currentIndex = 8
                }
                
                background: Rectangle {
                    x: trebleSlider.leftPadding
                    y: trebleSlider.topPadding + trebleSlider.availableHeight / 2 - height / 2
                    width: trebleSlider.availableWidth
                    height: Theme.sliderHeight
                    radius: 2
                    color: Theme.sliderTrack
                    
                    Rectangle {
                        width: trebleSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                }
                
                handle: Rectangle {
                    x: trebleSlider.leftPadding + trebleSlider.visualPosition * (trebleSlider.availableWidth - width)
                    y: trebleSlider.topPadding + trebleSlider.availableHeight / 2 - height / 2
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.accent
                }
            }
        }
    }
}

