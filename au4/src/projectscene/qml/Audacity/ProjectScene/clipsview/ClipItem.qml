import QtQuick

import Muse.Ui
import Muse.UiComponents
import Muse.GraphicalEffects

import Audacity.ProjectScene

Rectangle {

    id: root

    property alias context: waveView.context
    property alias clipKey: waveView.clipKey
    property alias title: titleLabel.text
    property color clipColor: "#677CE4"
    property bool clipSelected: false

    property real dragMaximumX: 100000
    property real dragMinimumX: -100000

    property bool collapsed: false

    signal positionChanged(x : double)
    signal requestSelected()

    signal titleEditStarted()
    signal titleEditAccepted(var newTitle)
    signal titleEditCanceled()

    radius: 4
    color: "#000000" // border color

    property int borderWidth: 1
    property bool hover: hoverArea.containsMouse || headerDragArea.containsMouse

    function editTitle() {
        editLoader.edit(titleLabel.text)
    }

    function acceptEditTitle(newTitle) {
        Qt.callLater(root.titleEditAccepted, newTitle)
    }

    ClipContextMenuModel {
        id: contextMenuModel
        clipKey: root.clipKey
    }

    Component.onCompleted: {
        contextMenuModel.load()
    }

    ContextMenuLoader {
        id: contextMenuLoader

        onHandleMenuItem: function(itemId) {
            contextMenuModel.handleMenuItem(itemId)
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        hoverEnabled: root.collapsed
        onClicked: function(e) {
            contextMenuLoader.show(Qt.point(e.x, e.y), contextMenuModel.items)
        }
    }

    Rectangle {
        id: inner

        anchors.fill: parent
        anchors.margins: root.borderWidth

        //! NOTE On Linux it often results in a black square
        // layer.enabled: true
        // layer.effect: EffectOpacityMask {
        //     maskSource: RoundedRectangle {
        //         width: inner.width
        //         height: inner.height
        //         radius: root.radius
        //     }
        // }

        Rectangle {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right

            height: 20
            z: 2

            visible: !root.collapsed || root.hover

            MouseArea {
                id: headerDragArea
                anchors.fill: parent

                hoverEnabled: true
                cursorShape: Qt.OpenHandCursor
                drag.target: root
                drag.axis: Drag.XAxis
                drag.maximumX: root.dragMaximumX
                drag.minimumX: root.dragMinimumX

                onReleased: {
                    if (drag.active) {
                        root.positionChanged(root.x)
                    }
                }

                onClicked: root.requestSelected()

                onDoubleClicked: {
                    root.editTitle()
                }
            }

            StyledTextLabel {
                id: titleLabel
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: menuBtn.left
                anchors.leftMargin: 4
                anchors.rightMargin: 8
                horizontalAlignment: Qt.AlignLeft
            }

            Loader {
                id: editLoader

                anchors.fill: titleLabel

                property bool isEditState: false
                sourceComponent: editLoader.isEditState ? titleEditComp : null

                function edit(text) {
                    root.titleEditStarted()
                    editLoader.isEditState = true
                    editLoader.item.currentText = text
                    editLoader.item.newTitle = text
                    editLoader.item.visible = true
                    editLoader.item.ensureActiveFocus()
                }
            }

            Component {
                id: titleEditComp
                TextInputField {
                    id: titleEdit

                    property string newTitle: ""

                    anchors.fill: parent
                    background.color: header.color
                    background.border.width: 0
                    background.radius: 0
                    inputField.color: titleLabel.color
                    textSidePadding: 0
                    visible: false

                    onTextChanged: function(text) {
                        titleEdit.newTitle = text
                    }

                    onAccepted: {
                        root.acceptEditTitle(titleEdit.newTitle)
                        editLoader.isEditState = false
                    }

                    onEscaped: {
                        editLoader.isEditState = false
                    }

                    onFocusChanged: {
                        if (!titleEdit.focus) {
                            titleEdit.visible = false
                        }
                    }
                }
            }

            MenuButton {
                id: menuBtn
                width: 16
                height: 16
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter

                menuModel: contextMenuModel

                onHandleMenuItem: function(itemId) {
                    contextMenuModel.handleMenuItem(itemId)
                }
            }
        }

        WaveView {
            id: waveView
            anchors.top: (!root.collapsed && header.visible) ? header.bottom : parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            clipColor: root.clipColor
            clipLeft: root.x
            clipSelected: root.clipSelected
        }
    }

    state: "NORMAL"
    states: [
        State {
            name: "NORMAL"
            when: !root.clipSelected && !headerDragArea.containsMouse
            PropertyChanges { target: header; color: root.clipColor }
            PropertyChanges { target: titleLabel; color: "#ffffff"}
            PropertyChanges { target: menuBtn; iconColor: "#ffffff"}
        },

        State {
            name: "SELECTED"
            when: root.clipSelected && !headerDragArea.containsMouse
            PropertyChanges { target: header; color: ui.blendColors("#ffffff", root.clipColor, 0.3) }
            PropertyChanges { target: titleLabel; color: "#000000" }
            PropertyChanges { target: menuBtn; iconColor: "#000000"}
        },

        State {
            name: "NORMAL_HEADER_HOVERED"
            when: !root.clipSelected && headerDragArea.containsMouse
            PropertyChanges { target: header; color: ui.blendColors("#ffffff", root.clipColor, 0.8)}
            PropertyChanges { target: titleLabel; color: "#ffffff"}
            PropertyChanges { target: menuBtn; iconColor: "#ffffff"}
        },

        State {
            name: "SELECTED_HEADER_HOVERED"
            when: root.clipSelected && headerDragArea.containsMouse
            PropertyChanges { target: header; color: ui.blendColors("#ffffff", root.clipColor, 0.2) }
            PropertyChanges { target: titleLabel; color: "#000000"}
            PropertyChanges { target: menuBtn; iconColor: "#000000"}
        }
    ]
}
