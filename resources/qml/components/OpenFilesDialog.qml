import QtQuick
import QtQuick.Dialogs

FileDialog {
    id: root

    property var controller

    title: "打开音乐文件"
    fileMode: FileDialog.OpenFiles
    currentFolder: root.controller ? root.controller.lastFolder : ""
    nameFilters: [
        "Music Files (*.mp3 *.flac *.wav *.m4a *.ogg *.oga *.aac *.opus *.wma *.3gp *.mp4 *.mov *.avi *.mkv *.webm)",
        "Audio Files (*.mp3 *.flac *.wav *.m4a *.ogg *.oga *.aac *.opus *.wma)",
        "Video Files (*.mp4 *.mov *.avi *.mkv *.webm *.3gp)",
        "All Files (*)"
    ]
    onAccepted: {
        if (root.controller) {
            root.controller.setPlaylistFromUrls(selectedFiles)
        }
    }
}
