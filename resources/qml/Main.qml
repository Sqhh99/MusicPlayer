import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import MusicPlayer
import "components"

ApplicationWindow {
    id: root

    visible: true
    width: targetWindowWidth
    height: targetWindowHeight
    minimumWidth: transitioning ? Theme.islandWidth : targetWindowWidth
    minimumHeight: transitioning ? Theme.islandHeight : targetWindowHeight
    maximumWidth: transitioning ? Theme.fullWidth : targetWindowWidth
    maximumHeight: transitioning ? Theme.fullHeight : targetWindowHeight

    flags: isPinned ? (Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint) 
                    : (Qt.Window | Qt.FramelessWindowHint)
    color: "transparent"
    title: "Music Player"
    font.family: Theme.fontFamily

    property bool isPinned: false
    property string windowMode: "full"
    readonly property bool isMiniMode: windowMode === "mini"
    readonly property bool isIslandMode: windowMode === "island"
    property bool showPlaylist: false
    property bool showLyrics: false
    property bool showEq: false
    property bool showSettings: false
    property bool isShuffle: false
    property bool compact: width < 900
    property bool transitioning: false
    readonly property int targetWindowWidth: isIslandMode
        ? Theme.islandWidth
        : (isMiniMode ? Theme.miniWidth : Theme.fullWidth)
    readonly property int targetWindowHeight: isIslandMode
        ? Theme.islandHeight
        : (isMiniMode ? Theme.miniHeight : Theme.fullHeight)
    readonly property int targetCornerRadius: isIslandMode
        ? Theme.radiusIsland
        : (isMiniMode ? Theme.radiusMini : Theme.radiusLarge)
    readonly property int nativeCornerRadius: targetCornerRadius

    Component.onCompleted: {
        syncWindowChrome()
        playerController.loadSavedPlaylist()
    }

    property var lyricsLines: [
        "Waiting in a car",
        "Waiting for a ride in the dark",
        "The night city grows",
        "Look and see her eyes, they glow",
        "Waiting in a car",
        "Waiting for a ride in the dark",
        "Drinking in the lounge",
        "Following the neon signs",
        "Waiting for a word",
        "Looking at the milky way",
        "The city is my church",
        "It wraps me in its blinding twilight",
        "Waiting in a car",
        "Waiting for the right time"
    ]

    function showMainWindow() {
        root.show()
        root.raise()
        root.requestActivate()
    }

    function syncWindowChrome() {
        windowEffects.cornerRadius = nativeCornerRadius
    }

    function positionIsland(force) {
        if (!force && !root.isIslandMode) {
            return
        }
        var screenX = Number.isFinite(Screen.virtualX) ? Screen.virtualX : 0
        var screenWidth = Number.isFinite(Screen.width) && Screen.width > 0
            ? Screen.width
            : Theme.islandWidth
        root.x = screenX + Math.round((screenWidth - Theme.islandWidth) / 2)
        root.y = Theme.islandTopMargin
    }

    function closeTransientPanels() {
        root.showPlaylist = false
        root.showEq = false
        root.showSettings = false
    }

    function setShuffleEnabled(enabled) {
        root.isShuffle = enabled
        if (enabled && playerController.isLooping) {
            playerController.isLooping = false
        }
    }

    function toggleShuffle() {
        setShuffleEnabled(!root.isShuffle)
    }

    function enterFullMode() {
        if (root.windowMode === "full" || root.transitioning) {
            return
        }
        modeTransition.switchTo("full")
    }

    function enterMiniMode() {
        if (root.windowMode === "mini" || root.transitioning) {
            return
        }
        if (root.windowMode === "full") {
            savedLyricsState = showLyrics
        }
        closeTransientPanels()
        root.showLyrics = false
        modeTransition.switchTo("mini")
    }

    function enterIslandMode() {
        if (root.windowMode === "island" || root.transitioning) {
            return
        }
        if (root.windowMode === "full") {
            savedLyricsState = showLyrics
        }
        closeTransientPanels()
        root.showLyrics = false
        root.isPinned = true
        modeTransition.switchTo("island")
    }

    function toggleMiniMode() {
        if (root.isMiniMode) {
            root.enterFullMode()
        } else {
            root.enterMiniMode()
        }
    }

    function openSettings() {
        if (root.windowMode !== "full") {
            root.enterFullMode()
        }
        root.closeTransientPanels()
        root.showSettings = true
    }

    // Preserve lyrics state when switching to mini mode
    property bool savedLyricsState: false

    onWindowModeChanged: {
        syncWindowChrome()
        if (isMiniMode || isIslandMode) {
            showLyrics = false
        } else {
            if (savedLyricsState && !showSettings) {
                showLyrics = true
            }
        }
        if (isIslandMode) {
            positionIsland()
        }
    }

    onShowPlaylistChanged: {
        if (showPlaylist) {
            showSettings = false
            showEq = false
        }
    }

    onShowLyricsChanged: {
        if (showLyrics) {
            showEq = false
        }
    }

    onShowSettingsChanged: {
        if (showSettings) {
            showPlaylist = false
            showEq = false
        }
    }

    Connections {
        target: playerController
        function onLoopingChanged() {
            if (playerController.isLooping && root.isShuffle) {
                root.isShuffle = false
            }
        }
    }

    // ── Mode Transition Animation Engine ──
    QtObject {
        id: modeTransition
        property string pendingMode: ""

        function switchTo(mode) {
            pendingMode = mode
            transitionAnimation.stop()
            transitionAnimation.start()
        }

        function targetW() {
            switch (pendingMode) {
            case "island": return Theme.islandWidth
            case "mini":   return Theme.miniWidth
            default:       return Theme.fullWidth
            }
        }

        function targetH() {
            switch (pendingMode) {
            case "island": return Theme.islandHeight
            case "mini":   return Theme.miniHeight
            default:       return Theme.fullHeight
            }
        }

        function targetR() {
            switch (pendingMode) {
            case "island": return Theme.radiusIsland
            case "mini":   return Theme.radiusMini
            default:       return Theme.radiusLarge
            }
        }

        function targetX() {
            if (pendingMode === "island") {
                var screenX = Number.isFinite(Screen.virtualX) ? Screen.virtualX : 0
                var screenWidth = Number.isFinite(Screen.width) && Screen.width > 0
                    ? Screen.width : Theme.islandWidth
                return screenX + Math.round((screenWidth - Theme.islandWidth) / 2)
            }
            // For other modes, keep current x (or center on screen if coming from island)
            if (root.isIslandMode) {
                var sw = Number.isFinite(Screen.width) && Screen.width > 0 ? Screen.width : targetW()
                var sx = Number.isFinite(Screen.virtualX) ? Screen.virtualX : 0
                return sx + Math.round((sw - targetW()) / 2)
            }
            return root.x
        }

        function targetY() {
            if (pendingMode === "island") {
                return Theme.islandTopMargin
            }
            if (root.isIslandMode) {
                var sh = Number.isFinite(Screen.height) && Screen.height > 0 ? Screen.height : targetH()
                return Math.round((sh - targetH()) / 2)
            }
            return root.y
        }
    }

    SequentialAnimation {
        id: transitionAnimation

        ScriptAction {
            script: {
                root.transitioning = true
            }
        }

        // Phase 1: Fade out current content
        NumberAnimation {
            target: contentArea
            property: "opacity"
            to: 0
            duration: 120
            easing.type: Easing.OutQuad
        }

        // Phase 2: Resize & reposition window, animate corner radius
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "width"
                to: modeTransition.targetW()
                duration: 360
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: root
                property: "height"
                to: modeTransition.targetH()
                duration: 360
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: root
                property: "x"
                to: modeTransition.targetX()
                duration: 360
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: root
                property: "y"
                to: modeTransition.targetY()
                duration: 360
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: surface
                property: "radius"
                to: modeTransition.targetR()
                duration: 360
                easing.type: Easing.InOutCubic
            }
        }

        // Phase 3: Apply new mode, then fade in
        ScriptAction {
            script: {
                root.windowMode = modeTransition.pendingMode
                syncWindowChrome()
            }
        }

        NumberAnimation {
            target: contentArea
            property: "opacity"
            to: 1
            duration: 160
            easing.type: Easing.InQuad
        }

        ScriptAction {
            script: {
                root.transitioning = false
            }
        }
    }

    Behavior on x {
        enabled: !dragArea.isDragging && !root.transitioning
        NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
    }
    Behavior on y {
        enabled: !dragArea.isDragging && !root.transitioning
        NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
    }

    onWidthChanged: {
        if (isIslandMode) {
            positionIsland()
        }
    }

    onHeightChanged: {
        if (isIslandMode) {
            positionIsland()
        }
    }

    onScreenChanged: {
        if (isIslandMode) {
            positionIsland()
        }
    }

    onVisibleChanged: {
        if (visible && isIslandMode) {
            positionIsland()
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: 0
        radius: root.transitioning ? surface.radius : targetCornerRadius
        color: root.isIslandMode ? Theme.islandBg : Theme.surfaceBg
        border.color: root.isIslandMode ? Theme.islandBorder : Theme.surfaceBorder
        border.width: root.isIslandMode ? 0 : 1
        clip: true

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.surfaceHighlight }
                GradientStop { position: 0.45; color: Theme.surfaceMidHighlight }
                GradientStop { position: 1.0; color: Theme.surfaceBottomTint }
            }
        }

        Rectangle {
            visible: !root.isIslandMode
            width: root.isMiniMode ? 180 : 320
            height: root.isMiniMode ? 120 : 260
            x: root.isMiniMode ? -24 : -72
            y: root.isMiniMode ? -30 : -88
            radius: width / 2
            color: Theme.surfaceGlowBlue
        }

        Rectangle {
            visible: !root.isIslandMode
            width: root.isMiniMode ? 120 : 220
            height: root.isMiniMode ? 120 : 220
            x: width + 90
            y: height - (root.isMiniMode ? 80 : 120)
            radius: width / 2
            color: Theme.surfaceGlowRose
        }

        Item {
            id: contentArea
            anchors.fill: parent

            FullPlayer {
                id: fullPlayer
                anchors.fill: parent
                visible: opacity > 0
                opacity: (isMiniMode || isIslandMode || showPlaylist || showSettings) ? 0 : 1
                controller: playerController
                appWindow: root
                showLyrics: root.showLyrics
                showEq: root.showEq
                showPlaylist: root.showPlaylist
                isShuffle: root.isShuffle
                compact: root.compact
                lyrics: root.lyricsLines
                onToggleLyrics: root.showLyrics = !root.showLyrics
                onToggleEq: root.showEq = !root.showEq
                onTogglePlaylist: root.showPlaylist = !root.showPlaylist
                onToggleShuffle: root.toggleShuffle()
                onOpenFilesRequested: fileDialog.open()

                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }

            MiniPlayer {
                id: miniPlayer
                anchors.fill: parent
                visible: opacity > 0
                opacity: (isMiniMode && !showSettings) ? 1 : 0
                controller: playerController
                title: playerController.currentSong
                artist: "本地音乐"
                isShuffle: root.isShuffle
                onToggleShuffle: root.toggleShuffle()

                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }

            DynamicIsland {
                id: dynamicIsland
                width: Theme.islandWidth
                height: Theme.islandHeight
                anchors.centerIn: parent
                visible: opacity > 0
                opacity: root.isIslandMode ? 1 : 0
                controller: playerController
                onOpenMiniRequested: root.enterMiniMode()

                Behavior on opacity {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                }
            }

            PlaylistOverlay {
                id: playlistOverlay
                anchors.fill: parent
                open: root.showPlaylist && !root.isMiniMode && !root.isIslandMode
                model: playerController.playlist
                currentIndex: playerController.currentIndex
                isPlaying: playerController.isPlaying
                appWindow: root
                onCloseRequested: root.showPlaylist = false
                onOpenFilesRequested: fileDialog.open()
                onSelectIndex: (index) => {
                    playerController.playIndex(index)
                    if (root.compact) {
                        root.showPlaylist = false
                    }
                }
            }

            SettingsOverlay {
                id: settingsOverlay
                anchors.fill: parent
                open: root.showSettings
                appWindow: root
                settings: appSettings
                onCloseRequested: root.showSettings = false
            }
        }

        WindowControls {
            id: windowControls
            z: 3
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 14
            anchors.rightMargin: 16
            visible: !showPlaylist && !showSettings && !isIslandMode
            miniMode: root.isMiniMode
            islandMode: root.isIslandMode
            isPinned: root.isPinned
            settingsOpen: root.showSettings
            onToggleMiniRequested: root.toggleMiniMode()
            onOpenIslandRequested: root.enterIslandMode()
            onMinimizeRequested: root.showMinimized()
            onCloseRequested: root.hide()
            onTogglePinRequested: root.isPinned = !root.isPinned
            onOpenSettingsRequested: root.openSettings()
        }

        WindowDragArea {
            id: dragArea
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            appWindow: root
            isMiniMode: root.isMiniMode
            isIslandMode: root.isIslandMode
            showPlaylist: root.showPlaylist
            showEq: root.showEq
            showSettings: root.showSettings
        }
    }

    OpenFilesDialog {
        id: fileDialog
        controller: playerController
    }

    AppShortcuts {
        controller: playerController
        appWindow: root
    }

    TrayIcon {
        id: trayIcon
        appWindow: root
        controller: playerController
        isShuffle: root.isShuffle
        onToggleShuffleRequested: root.toggleShuffle()
    }
}
