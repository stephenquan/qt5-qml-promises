import QtQuick 2.15

Item {
    property var errorHandler: null

    QtObject {
        id: internal

        property double userAbortTime: 0
    }

    function userAbort() {
        internal.userAbortTime = Date.now();
    }

    function invoke(promiseComponent, props) {
        return new Promise(function (resolve, reject) {
            let _props = props ?? { };
            _props.resolve = resolve;
            _props.reject = reject;
            _props.userAbortTime = Qt.binding(() => internal.userAbortTime);

            try {
                promiseComponent.createObject(null, _props);
            } catch (err) {
                reject(err);
            }
        } );
    }

    function sleep(interval) {
        return invoke(sleepComponent, { interval } );
    }

    function numberAnimation(target, property, from, to, duration) {
        return invoke(numberAnimationComponent, { target, property, from, to, duration } );
    }

    function grabToImage(item, filePath) {
        return new Promise(function (resolve, reject) {
            try {
                item.grabToImage(function (result) {
                    try {
                        if (!result.saveToFile(filePath)) {
                            reject(new Error(qStr("grabToImage error: %1").arg(filePath)));
                            return;
                        }
                        resolve(filePath);
                    } catch (saveError) {
                        reject(saveError);
                    }
                } );
            } catch (grabError) {
                reject(grabError);
            }
        } );
    }

    SleepPromiseComponent {
        id: sleepComponent
    }

    NumberAnimationComponent {
        id: numberAnimationComponent
    }

    function asyncToGenerator(fn) {
        return _asyncToGenerator( function* () {
            try {
                yield *fn();
            } catch (err) {
                let _errorHandler = errorHandler ?? defaultErrorHandler;
                _errorHandler(err);
            }
        } );
    }

    function _asyncToGenerator(fn) {
        return function() {
            var self = this,
            args = arguments
            return new Promise(function(resolve, reject) {
                var gen = fn.apply(self, args)
                function _next(value) {
                    _asyncGeneratorStep(gen, resolve, reject, _next, _throw, "next", value)
                }
                function _throw(err) {
                    _asyncGeneratorStep(gen, resolve, reject, _next, _throw, "throw", err)
                }
                _next(undefined)
            })
        }
    }

    function _asyncGeneratorStep(gen, resolve, reject, _next, _throw, key, arg) {
        try {
            var info = gen[key](arg)
            var value = info.value
        } catch (error) {
            reject(error)
            return
        }
        if (info.done) {
            resolve(value)
        } else {
            Promise.resolve(value).then(_next, _throw)
        }
    }

    function defaultErrorHandler(err) {
        let fileName = err.fileName ?? "";
        let lineNumber = err.lineNumber ?? 1;
        let columnNumber = err.columnNumber ?? 1;
        let message = err.message ?? "";
        console.error(fileName + ":" + lineNumber + ":" + columnNumber + ": " + message);
        throw err;
    }
}
