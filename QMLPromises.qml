import QtQuick 2.15

Item {
    property var errorHandler: null
    property var owner: null
    property double userAbortTime: 0

    function userAbort() {
        userAbortTime = Date.now();
    }

    function invoke(promiseComponent, props) {
        return new Promise(function (resolve, reject) {
            let _props = props ?? { };
            _props.resolve = resolve;
            _props.reject = reject;
            _props.userAbortTime = Qt.binding(() => userAbortTime);

            try {
                promiseComponent.createObject(owner, _props);
            } catch (err) {
                reject(err);
            }
        } );
    }

    function sleep(interval) {
        return invoke(sleepComponent, { interval } );
    }

    function numberAnimation(properties) {
        return invoke(numberAnimationComponent, properties);
    }

    function fetch(properties) {
        return new Promise(function (resolve, reject) {
            let _prop = properties ?? { };
            let method = _prop["method"] ?? "GET";
            let url = _prop["url"] ?? "https://www.arcgis.com";
            let body = _prop["body"] ?? null;

            let xmlhttp = new XMLHttpRequest();
            xmlhttp.onreadystatechange = function() {
                if (xmlhttp.readyState !== XMLHttpRequest.DONE) {
                    return;
                }

                let responseJson = null;
                try {
                    responseJson = JSON.parse(xmlhttp.responseText);
                } catch (parseErr) {
                    reject(parseErr);
                }

                let obj = {
                    response: responseJson,
                    responseText: xmlhttp.responseText
                };

                Qt.callLater(resolve, obj);
            };

            if (body) {
                let query = [ ];
                for (let key in body) {
                    let value = body[key];
                    query.push(key + "=" + encodeURIComponent(value));
                }
                let queryString = query.join("&");

                xmlhttp.open(method, url + "?" + queryString);
                xmlhttp.send();
            } else {
                xmlhttp.open(method, url);
                xmlhttp.send();
            }
        } );
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

    NumberAnimationPromiseComponent {
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
