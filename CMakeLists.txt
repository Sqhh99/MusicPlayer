cmake_minimum_required(VERSION 3.16)

project(MusicPlayer VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Find Qt packages
find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2 Multimedia)

qt_standard_project_setup(REQUIRES 6.5)

# Backend sources (pure C++ business logic)
set(BACKEND_SOURCES
    src/backend/musicplayer.cpp
    src/backend/musicplayer.h
    src/backend/musicsettings.cpp
    src/backend/musicsettings.h
)

# App/Bridge sources (C++ <-> QML bridge layer)
set(APP_SOURCES
    src/app/PlayerController.cpp
    src/app/PlayerController.h
    src/app/PlaylistModel.cpp
    src/app/PlaylistModel.h
)

# Windows icon resource
set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/Icon.rc")

# Create executable with QML module
qt_add_executable(MusicPlayer
    src/main.cpp
    ${BACKEND_SOURCES}
    ${APP_SOURCES}
    ${app_icon_resource_windows}
)

# Set Theme.qml as singleton before adding to module
set_source_files_properties(resources/qml/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

# Add QML module - all QML files in same directory for simpler imports
qt_add_qml_module(MusicPlayer
    URI MusicPlayer
    VERSION 1.0
    QML_FILES
        resources/qml/Main.qml
        resources/qml/Theme.qml
        resources/qml/components/IconButton.qml
        resources/qml/components/ProgressBar.qml
        resources/qml/components/AlbumArt.qml
        resources/qml/components/EqualizerBars.qml
        resources/qml/components/WindowControls.qml
        resources/qml/components/VolumeControl.qml
        resources/qml/components/LyricsPanel.qml
        resources/qml/components/PlaylistOverlay.qml
        resources/qml/components/EqualizerPanel.qml
        resources/qml/components/MiniPlayer.qml
        resources/qml/components/FullPlayer.qml
    RESOURCES
        resources/icons/listen1.ico
        resources/icons/chevron-down.png
        resources/icons/list-music.png
        resources/icons/maximize-2.png
        resources/icons/mic-vocal.png
        resources/icons/minus.png
        resources/icons/pause.png
        resources/icons/play.png
        resources/icons/repeat.png
        resources/icons/shuffle.png
        resources/icons/skip-back.png
        resources/icons/skip-forward.png
        resources/icons/sliders-vertical.png
        resources/icons/volume-2.png
        resources/icons/volume-x.png
        resources/icons/x.png
)

# Link libraries
target_link_libraries(MusicPlayer PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
)

# Include directories
target_include_directories(MusicPlayer PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Set target properties
set_target_properties(MusicPlayer PROPERTIES
    WIN32_EXECUTABLE FALSE
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_GUI_IDENTIFIER com.musicplayer.app
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
)

# Installation
include(GNUInstallDirs)
install(TARGETS MusicPlayer
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
