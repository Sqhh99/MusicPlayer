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
        resources/qml/TitleBar.qml
        resources/qml/PlayerControls.qml
        resources/qml/ProgressSlider.qml
        resources/qml/VolumePopup.qml
        resources/qml/PlaylistView.qml
        resources/qml/EqualizerDialog.qml
        resources/qml/Theme.qml
    RESOURCES
        resources/icons/listen1.ico
        resources/icons/pause01.png
        resources/icons/player01.png
        resources/icons/File1.png
        resources/icons/icon_next.png
        resources/icons/icon_previous.png
        resources/icons/player_volume_increase.png
        resources/icons/ShunxuBof3.png
        resources/icons/xunhuanbof2.png
        resources/icons/playlist_icon.png
        resources/icons/playlist_icon_active.png
        resources/icons/zhiding.png
        resources/icons/yizhiding.png
        resources/icons/zuixiaohua.png
        resources/icons/equalizer.png
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
