import QtQuick
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property string source: ""
    property color tintColor: "white"

    Image {
        id: sourceImage
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    Rectangle {
        id: tintLayer
        anchors.fill: parent
        color: root.tintColor
        visible: false
    }

    OpacityMask {
        anchors.fill: parent
        source: tintLayer
        maskSource: sourceImage
    }
}
