# qt5-qml-promises

Implements JavaScript Promise wrapper for chaining QML events together.

The QMLPromises implements the following methods:

 - abort() - cancel an currently running Promise chain.
 - sleep(delay) - a Promise wrapper for Timer. Pauses a Promise chain specified in milliseconds.
 - pass() - a Promise wrapper for Qt.callLater. Introduces a small pause in a Promise chain.
 - numberAnimation( {target, property, from, to, duratio } n) - a Promise wrapper for NumberAnimation. Change a property from one value to another over a duration specified in milliseconds.
 - fetch(properties) - a Promise wrapper for XMLHttpRequest.
 - grabToImage(item, filePath) - saves a screen grab of an item to file.
 - asyncToGenerator(fn) - transcode async function with await to function generator with yield.

To see a demonstration of this library refer to:

 - https://github.com/stephenquan/qt5-qml-promises-demo
 
To use QMLPromises QML component in your project consider cloning this repo directly in your project:

    git clone https://github.com/stephenquan/qt5-qml-promises.git
    
or adding it as a submodule:

    git submodule add https://github.com/stephenquan/qt5-qml-promises.git qt5-qml-promises
    git submodule update
