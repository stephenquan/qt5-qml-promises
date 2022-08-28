import QtQuick 2.15

Component {
    id: numberAnimationComponent

    NumberAnimation {
        property var _resolve
        property var _reject
        property var _abort
        property bool _aborted: false
        property bool _aborting: false

        loops: 1
        paused: false
        running: true

        onFinished: {
            if (_aborted) {
                return;
            }

            stop();
            _resolve();
            Qt.callLater(destroy);
        }

        on_AbortingChanged: {
            if (_aborting) {
                if (running) {
                    stop();
                    _abort(_reject);
                    Qt.callLater(destroy);
                }
            }
        }
    }
}
