# qt5-qml-promises

Implements JavaScript Promise wrapper for chaining QML events together.

The QMLPromises singleton implements the following methods:

 - QMLPromises.userBreak()
 - QMLPromises.sleep(interval)
 - QMLPromises.numberAnimation(target, properties, from, to, duration)

Here's a brief description of each method:

QMLPromises.userBreak() - cancel previous running QMLPromises.
QMLPromises.sleep(interval) - introduce a pause in the promise chain specified in milliseconds
QMLPromises.numberAnimation(target, proprerties, from, to, duration) - change a property from one value to another over a duration specified in milliseconds

The following animates an SVG bicycle moving along a square permiter.

```qml
import "qt5-qml-promises"

Page {
    anchors.fill: parent

    footer: Frame {
        Button {
            id: button
            anchors.centerIn: parent
            text: qsTr("Go")

            onClicked: {
                bicycle.x = 100;
                bicycle.y = 400;
                bicycle.rotation = 0;

                QMLPromises.userBreak();

                Promise.resolve()
                .then( function () {
                    message.text = qsTr("On your marks!");
                    message.color = "black";
                    messageFrame.background.color = "red";
                    return QMLPromises.numberAnimation(messageFrame, "opacity", 1.0, 0.0, 1000);
                } )
                .then( function () {
                    message.text = qsTr("Get set!")
                    message.color = "black";
                    messageFrame.background.color = "yellow";
                    return QMLPromises.numberAnimation(messageFrame, "opacity", 1.0, 0.0, 1000);
                } )
                .then( function () {
                    message.text = qsTr("Go!")
                    message.color = "white";
                    messageFrame.background.color = "green";
                    return QMLPromises.numberAnimation(messageFrame, "opacity", 1.0, 0.0, 1000);
                } )
                .then( () => QMLPromises.numberAnimation(bicycle, "x", 100, 300, 1000) )
                .then( () => QMLPromises.numberAnimation(bicycle, "rotation", 0, -90, 500) )
                .then( () => QMLPromises.numberAnimation(bicycle, "y", 400, 200, 1000) )
                .then( () => QMLPromises.numberAnimation(bicycle, "rotation", -90, -180, 500) )
                .then( () => QMLPromises.numberAnimation(bicycle, "x", 300, 100, 1000) )
                .then( () => QMLPromises.numberAnimation(bicycle, "rotation", 180, 90, 500) )
                .then( () => QMLPromises.numberAnimation(bicycle, "y", 200, 400, 1000) )
                .then( () => QMLPromises.numberAnimation(bicycle, "rotation", 90, 0, 500) )
                .catch( err => errorHandler(err) )
                ;
            }
        }
    }

    Item {
        id: bicycle
        x: 100
        y: 400
        width: 0
        height: 0
        property color color: "blue"

        Button {
            id: bicycleButton
            anchors.centerIn: parent
            background: Item { }
            icon.source: "https://raw.githubusercontent.com/Esri/calcite-ui-icons/master/icons/biking-32.svg"
            icon.width: 64
            icon.height: 64
            icon.color: parent.color
        }
    }

    Frame {
        id: messageFrame
        anchors.centerIn: parent
        opacity: 0.0
        background: Rectangle {
            color: "blue"
            radius: 5
        }
        Text {
            id: message
            color: "black"
        }
    }

    function errorHandler(err) {
        console.error(err.message, err.stack);
        throw err;
    }
}
```

To use QMLPromises QML component in your project consider cloning this repo directly in your project:

    git clone https://github.com/stephenquan/qt5-qml-promises.git
    
or adding it as a submodule:

    git submodule add https://github.com/stephenquan/qt5-qml-promises.git qt5-qml-promises
    git submodule update
