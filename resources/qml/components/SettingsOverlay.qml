import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import MusicPlayer
import "./"

Rectangle {
    id: root

    property bool open: false
    property var appWindow: null
    property var settings

    signal closeRequested()

    visible: open || opacity > 0
    opacity: open ? 1 : 0

    color: Theme.surfaceOverlayBg
    border.color: Theme.surfaceOverlayBorder
    border.width: 1
    clip: true
    z: 5

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
    }

    property int sidebarWidth: 190
    property int headerHeight: 56
    property int sectionSpacing: 22
    property int sectionInset: 24

    Rectangle {
        id: sidebar
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.sidebarWidth
        color: Theme.surfacePanelBg
        border.width: 0

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 18

            Text {
                text: "设置"
                font.pixelSize: 24
                font.family: Theme.fontFamily
                font.weight: Font.DemiBold
                color: Theme.textPrimary
            }

            Rectangle {
                width: parent.width
                height: 46
                radius: 14
                color: Theme.materialButtonActiveBg
                border.color: Theme.materialButtonBorder
                border.width: 1

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    spacing: 10

                    TintedIcon {
                        source: Theme.iconPath + "monitor.png"
                        width: 16
                        height: 16
                        tintColor: Theme.buttonIconColor
                    }

                    Text {
                        text: "界面"
                        font.pixelSize: 14
                        font.family: Theme.fontFamily
                        font.weight: Font.DemiBold
                        color: Theme.textPrimary
                    }
                }
            }
        }
    }

    Item {
        id: contentArea
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: sidebar.right
        anchors.right: parent.right

        Rectangle {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: root.headerHeight
            color: "transparent"

            OverlayCloseButton {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                onClicked: root.closeRequested()
            }

            MouseArea {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.rightMargin: 54
                hoverEnabled: true
                cursorShape: Qt.SizeAllCursor

                property point dragStartPos: Qt.point(0, 0)
                property bool dragging: false

                onPressed: (mouse) => {
                    if (!root.appWindow || mouse.button !== Qt.LeftButton) {
                        return
                    }
                    dragging = true
                    dragStartPos = Qt.point(mouse.x, mouse.y)
                }
                onPositionChanged: (mouse) => {
                    if (!dragging || !root.appWindow) {
                        return
                    }
                    var globalPos = mapToGlobal(mouse.x, mouse.y)
                    root.appWindow.x = globalPos.x - dragStartPos.x
                    root.appWindow.y = globalPos.y - dragStartPos.y
                }
                onReleased: dragging = false
                onCanceled: dragging = false
            }
        }

        Flickable {
            id: flickable
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            contentWidth: width
            contentHeight: settingsContent.implicitHeight + 36
            clip: true

            Column {
                id: settingsContent
                width: flickable.width
                spacing: root.sectionSpacing
                anchors.top: parent.top
                anchors.topMargin: 4

                Item {
                    width: parent.width
                    implicitHeight: themeSection.implicitHeight + (root.sectionInset * 2)

                    Column {
                        id: themeSection
                        anchors.fill: parent
                        anchors.margins: root.sectionInset
                        spacing: 14

                        Text {
                            text: "主题"
                            font.pixelSize: 16
                            font.family: Theme.fontFamily
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }

                        Row {
                            spacing: 14

                            Repeater {
                                model: [
                                    { value: "day", label: "白天", hint: "明亮半透明界面" },
                                    { value: "night", label: "黑夜", hint: "深色材质界面" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    width: 190
                                    height: 104
                                    radius: 18
                                    color: settings && settings.themeMode === modelData.value
                                        ? Theme.materialButtonActiveBg
                                        : Theme.surfacePanelBg
                                    border.color: settings && settings.themeMode === modelData.value
                                        ? Theme.accent
                                        : Theme.surfacePanelBorder
                                    border.width: 1

                                    Column {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.margins: 16
                                        spacing: 6

                                        Text {
                                            text: modelData.label
                                            font.pixelSize: 15
                                            font.family: Theme.fontFamily
                                            font.weight: Font.DemiBold
                                            color: Theme.textPrimary
                                        }

                                        Text {
                                            text: modelData.hint
                                            font.pixelSize: 12
                                            font.family: Theme.fontFamily
                                            color: Theme.textSubtle
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (settings) { settings.themeMode = modelData.value }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    implicitHeight: materialSection.implicitHeight + (root.sectionInset * 2)

                    Column {
                        id: materialSection
                        anchors.fill: parent
                        anchors.margins: root.sectionInset
                        spacing: 18

                        Text {
                            text: "材质"
                            font.pixelSize: 16
                            font.family: Theme.fontFamily
                            font.weight: Font.DemiBold
                            color: Theme.textPrimary
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "界面材质强度"
                                font.pixelSize: 14
                                font.family: Theme.fontFamily
                                color: Theme.textSecondary
                            }

                            Slider {
                                id: materialStrengthSlider
                                width: parent.width
                                from: 0
                                to: 100
                                value: settings ? settings.materialStrength : 72
                                onMoved: if (settings) { settings.materialStrength = Math.round(value) }
                                onValueChanged: if (pressed && settings) { settings.materialStrength = Math.round(value) }

                                background: Rectangle {
                                    x: materialStrengthSlider.leftPadding
                                    y: materialStrengthSlider.topPadding + (materialStrengthSlider.availableHeight - height) / 2
                                    width: materialStrengthSlider.availableWidth
                                    height: 6
                                    radius: 3
                                    color: Theme.trackBg

                                    Rectangle {
                                        width: materialStrengthSlider.visualPosition * parent.width
                                        height: parent.height
                                        radius: parent.radius
                                        color: Theme.accent
                                    }
                                }

                                handle: Rectangle {
                                    x: materialStrengthSlider.leftPadding
                                        + (materialStrengthSlider.visualPosition * (materialStrengthSlider.availableWidth - width))
                                    y: materialStrengthSlider.topPadding
                                        + (materialStrengthSlider.availableHeight - height) / 2
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: Theme.handle
                                    border.color: Theme.surfacePanelBorder
                                    border.width: 1
                                }
                            }

                            Text {
                                text: (settings ? settings.materialStrength : 72) + "%"
                                font.pixelSize: 12
                                font.family: Theme.fontFamilyMono
                                color: Theme.textMuted
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "按钮材质强度"
                                font.pixelSize: 14
                                font.family: Theme.fontFamily
                                color: Theme.textSecondary
                            }

                            Slider {
                                id: buttonMaterialSlider
                                width: parent.width
                                from: 0
                                to: 100
                                value: settings ? settings.buttonMaterialStrength : 62
                                onMoved: if (settings) { settings.buttonMaterialStrength = Math.round(value) }
                                onValueChanged: if (pressed && settings) { settings.buttonMaterialStrength = Math.round(value) }

                                background: Rectangle {
                                    x: buttonMaterialSlider.leftPadding
                                    y: buttonMaterialSlider.topPadding + (buttonMaterialSlider.availableHeight - height) / 2
                                    width: buttonMaterialSlider.availableWidth
                                    height: 6
                                    radius: 3
                                    color: Theme.trackBg

                                    Rectangle {
                                        width: buttonMaterialSlider.visualPosition * parent.width
                                        height: parent.height
                                        radius: parent.radius
                                        color: Theme.accent
                                    }
                                }

                                handle: Rectangle {
                                    x: buttonMaterialSlider.leftPadding
                                        + (buttonMaterialSlider.visualPosition * (buttonMaterialSlider.availableWidth - width))
                                    y: buttonMaterialSlider.topPadding
                                        + (buttonMaterialSlider.availableHeight - height) / 2
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: Theme.handle
                                    border.color: Theme.surfacePanelBorder
                                    border.width: 1
                                }
                            }

                            Text {
                                text: (settings ? settings.buttonMaterialStrength : 62) + "%"
                                font.pixelSize: 12
                                font.family: Theme.fontFamilyMono
                                color: Theme.textMuted
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 62
                            radius: 16
                            color: glowButtonArea.pressed
                                ? Theme.materialButtonPressedBg
                                : (glowButtonArea.containsMouse ? Theme.materialButtonHoverBg : "transparent")
                            border.color: glowButtonArea.containsMouse ? Theme.materialButtonBorder : "transparent"
                            border.width: glowButtonArea.containsMouse ? 1 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        text: "显示背景光晕"
                                        font.pixelSize: 14
                                        font.family: Theme.fontFamily
                                        color: Theme.textSecondary
                                    }

                                    Text {
                                        text: "控制顶部和底部的装饰性光晕"
                                        font.pixelSize: 12
                                        font.family: Theme.fontFamily
                                        color: Theme.textMuted
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    implicitWidth: 42
                                    implicitHeight: 24
                                    radius: height / 2
                                    color: settings && settings.backgroundGlowEnabled ? Theme.accent : Theme.trackBg
                                    border.color: settings && settings.backgroundGlowEnabled
                                        ? Theme.accent
                                        : Theme.surfacePanelBorder
                                    border.width: 1

                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 9
                                        x: settings && settings.backgroundGlowEnabled ? parent.width - width - 3 : 3
                                        y: 3
                                        color: Theme.handle

                                        Behavior on x {
                                            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: glowButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (settings) {
                                        settings.backgroundGlowEnabled = !settings.backgroundGlowEnabled
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
