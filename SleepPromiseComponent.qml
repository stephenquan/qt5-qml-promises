import QtQuick 2.15

Component {
    id: sleepComponent

    Timer {
        property var _resolve
        property var _reject
        property var _abort
        property bool _aborted: false
        property bool _aborting: false

        running: true
        repeat: false

        onTriggered: {
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
