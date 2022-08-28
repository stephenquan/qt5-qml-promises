import QtQuick 2.15

Component {
    QtObject {
        property var _resolve
        property var _reject
        property var _abort
        property bool _aborted: false
        property bool _aborting: false

        property var target
        property string property
        property var value
        property bool finished: target[property] === value

        onFinishedChanged: {
            if (_aborted) {
                return;
            }

            if (!finished) {
                return;
            }

            _resolve();
            Qt.callLater(destroy);
        }

        on_AbortingChanged: {
            if (_aborting) {
                _abort(_reject);
                Qt.callLater(destroy);
            }
        }
    }
}
