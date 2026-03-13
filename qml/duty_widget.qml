import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import RinUI
import ClassWidgets.Theme

Widget {
    id: root
    text: "今日值日生"
    width: 200

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentLayout.height
        clip: true
        interactive: true

        ColumnLayout {
            id: contentLayout
            width: parent.width
            spacing: 8

            Text {
                id: dutyText
                text: "加载中..."
                font.pointSize: 20
                font.bold: true
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                color: root.miniMode ? "#000" : (Theme.isDark() ? "#fff" : "#000")

                // 内容变化时重新检查是否需要滚动
                onTextChanged: restartAnimTimer.restart()
            }
        }
    }

    // 延迟启动动画的 Timer（等待布局稳定）
    Timer {
        id: restartAnimTimer
        interval: 500
        onTriggered: checkAndStartScroll()
    }

    // 自动滚动动画（循环：向下滚动至底部，然后平滑回滚到顶部）
    SequentialAnimation {
        id: autoScrollAnim
        loops: Animation.Infinite

        NumberAnimation {
            id: scrollDown
            target: flickable
            property: "contentY"
            duration: 0   // 动态计算
            easing.type: Easing.Linear
        }

        NumberAnimation {
            target: flickable
            property: "contentY"
            to: 0
            duration: 1000
            easing.type: Easing.InOutQuad
        }
    }

    function checkAndStartScroll() {
        autoScrollAnim.stop()
        flickable.contentY = 0

        // 内容为空或仅加载提示时不滚动
        if (dutyText.text === "加载中..." || dutyText.text === "") return;

        // 如果内容高度大于可视区域，则启动滚动
        if (contentLayout.height > flickable.height) {
            var distance = contentLayout.height - flickable.height
            scrollDown.to = distance
            // 滚动速度：每 50ms 移动 1 像素（可调整）
            scrollDown.duration = Math.max(1000, distance * 30)
            autoScrollAnim.start()
        }
    }

    onBackendChanged: {
        if (backend) {
            backend.update_duty_info()
        }
    }

    // 窗口缩放时重新计算滚动
    onHeightChanged: restartAnimTimer.restart()

    // 连接后端信号，更新显示内容
    Connections {
        target: backend
        function onContentUpdated(duty_names) {
            dutyText.text = duty_names
        }
    }
}
