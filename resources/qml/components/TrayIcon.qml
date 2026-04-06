import QtQuick
import Qt.labs.platform as Platform

Platform.SystemTrayIcon {
    id: root

    property var controller
    property var appWindow
    property bool isShuffle: false

    signal toggleShuffleRequested()

    visible: available
    icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/listen1.ico"
    tooltip: {
        var text = "Music Player"
        if (root.controller && root.controller.currentSong.length > 0) {
            text = root.controller.currentSong
            if (root.controller.isPlaying) {
                text += " - 播放中"
            } else if (root.controller.isPaused) {
                text += " - 已暂停"
            }
        }
        return text
    }
    menu: Platform.Menu {
        Platform.MenuItem {
            text: root.appWindow && root.appWindow.visible ? "隐藏窗口" : "显示窗口"
            icon.source: root.appWindow && root.appWindow.visible
                ? "qrc:/qt/qml/MusicPlayer/resources/icons/minus.png"
                : "qrc:/qt/qml/MusicPlayer/resources/icons/picture-in-picture.png"
            onTriggered: {
                if (!root.appWindow) {
                    return
                }
                if (root.appWindow.visible) {
                    root.appWindow.hide()
                } else {
                    root.appWindow.showMainWindow()
                }
            }
        }
        Platform.MenuSeparator { }
        Platform.MenuItem {
            text: root.controller && root.controller.isPlaying ? "暂停" : "播放"
            icon.source: root.controller && root.controller.isPlaying
                ? "qrc:/qt/qml/MusicPlayer/resources/icons/pause.png"
                : "qrc:/qt/qml/MusicPlayer/resources/icons/play.png"
            onTriggered: {
                if (root.controller) {
                    root.controller.togglePlayPause()
                }
            }
        }
        Platform.MenuItem {
            text: "上一首"
            icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/skip-back.png"
            onTriggered: {
                if (root.controller) {
                    root.controller.previous()
                }
            }
        }
        Platform.MenuItem {
            text: "下一首"
            icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/skip-forward.png"
            onTriggered: {
                if (root.controller) {
                    root.controller.next()
                }
            }
        }

        Platform.MenuSeparator { }

        Platform.MenuItem {
            text: "增加音量"
            icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/volume-2.png"
            onTriggered: {
                if (root.controller) {
                    root.controller.volume = Math.min(100, root.controller.volume + 10)
                }
            }
        }
        Platform.MenuItem {
            text: "减小音量"
            icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/volume-2.png"
            onTriggered: {
                if (root.controller) {
                    root.controller.volume = Math.max(0, root.controller.volume - 10)
                }
            }
        }
        Platform.MenuItem {
            text: root.controller && root.controller.isMuted ? "取消静音" : "静音"
            icon.source: root.controller && root.controller.isMuted
                ? "qrc:/qt/qml/MusicPlayer/resources/icons/volume-x.png"
                : "qrc:/qt/qml/MusicPlayer/resources/icons/volume-2.png"
            onTriggered: {
                if (root.controller) {
                    root.controller.isMuted = !root.controller.isMuted
                }
            }
        }

        Platform.MenuSeparator { }

        Platform.MenuItem {
            text: "循环播放"
            icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/repeat.png"
            checkable: true
            checked: root.controller ? root.controller.isLooping : false
            onTriggered: {
                if (root.controller) {
                    root.controller.isLooping = !root.controller.isLooping
                }
            }
        }

        Platform.MenuItem {
            text: "随机播放"
            icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/shuffle.png"
            checkable: true
            checked: root.isShuffle
            onTriggered: root.toggleShuffleRequested()
        }

        Platform.MenuSeparator { }

        Platform.MenuItem {
            text: "退出"
            icon.source: "qrc:/qt/qml/MusicPlayer/resources/icons/x.png"
            onTriggered: Qt.quit()
        }
    }

    onActivated: (reason) => {
        if (reason === Platform.SystemTrayIcon.Trigger
            || reason === Platform.SystemTrayIcon.DoubleClick) {
            if (root.appWindow) {
                root.appWindow.showMainWindow()
            }
        } else if (reason === Platform.SystemTrayIcon.MiddleClick) {
            if (root.controller) {
                root.controller.togglePlayPause()
            }
        }
    }
}
