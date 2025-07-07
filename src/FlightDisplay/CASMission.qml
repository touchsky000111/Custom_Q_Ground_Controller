import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controllers
import QGroundControl.Controls
import QGroundControl.FactSystem
import QGroundControl.FlightDisplay
import QGroundControl.FlightMap
import QGroundControl.Palette
import QGroundControl.ScreenTools
import QGroundControl.Vehicle



Dialog {
    id: casMissionDialog
    title: qsTr("CAS Mission")
    modal: true
    width: 400
    height: implicitHeight

    property bool isVisible: false
    visible: isVisible

    property string coordinateFormat: "MGRS"

    property var vehicle:  QGroundControl.multiVehicleManager.activeVehicle

    ColumnLayout {
        spacing: 12
        Layout.margins: 16

        // Heading
        RowLayout {
            Label { text: qsTr("Heading:") }
            ComboBox {
                id: headingBox
                model: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
            }
        }

        // Approach Alt.
        RowLayout {
            Label { text: qsTr("Approach Alt. (m):") }
            TextField {
                id: approachAltField
                placeholderText: qsTr("Enter altitude...")
                inputMethodHints: Qt.ImhDigitsOnly
            }
        }


        GroupBox {
            title: qsTr("Vehicle Status")
            visible: casMissionDialog.vehicle !== null
            ColumnLayout {
                Label {
                    text: qsTr("Armed: ") + (casMissionDialog.vehicle && casMissionDialog.vehicle.armed ? qsTr("Yes") : qsTr("No"))
                }
                Label {
                    text: qsTr("Flight Mode: ") + (casMissionDialog.vehicle ? casMissionDialog.vehicle.flightMode : qsTr("-"))
                }
                // Label {
                //     text: qsTr("Location: ") + (casMissionDialog.vehicle
                //         ? casMissionDialog.vehicle.latitude + ", " + casMissionDialog.vehicle.longitude + casMissionDialog.vehicle.coordinate +  "  ": qsTr("N/A"))
                // }

                // Label {
                //     text: qsTr("Battery: ") + (casMissionDialog.vehicle
                //         ?  casMissionDialog.vehicle.batteries.get(0) + "%"
                //         : qsTr("-"))
                // }

            }
        }


        // Location
        GroupBox {
            title: qsTr("Location")
            ColumnLayout {
                RadioButton {
                    text: qsTr("MGRS")
                    checked: casMissionDialog.coordinateFormat === "MGRS"
                    onCheckedChanged: {
                        if (checked) casMissionDialog.coordinateFormat = "MGRS"
                    }
                }
                RadioButton {
                    text: qsTr("Lat/Lon")
                    checked: casMissionDialog.coordinateFormat === "LatLon"
                    onCheckedChanged: {
                        if (checked) casMissionDialog.coordinateFormat = "LatLon"
                    }
                }
                TextField {
                    id: coordinateField
                    placeholderText: casMissionDialog.coordinateFormat === "MGRS"
                                     ? qsTr("Enter MGRS coordinate...")
                                     : qsTr("Enter Lat, Lon...")
                }
            }
        }

        // Egress Direction
        RowLayout {
            Label { text: qsTr("Egress Direction:") }
            ComboBox {
                id: egressBox
                model: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
            }
        }

        // Egress Alt.
        RowLayout {
            Label { text: qsTr("Egress Alt. (m):") }
            TextField {
                id: egressAltField
                placeholderText: qsTr("Enter altitude...")
                inputMethodHints: Qt.ImhDigitsOnly
            }
        }

        // Action Buttons
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10
            Button {
                text: qsTr("Cancel")
                onClicked: {
                    casMissionDialog.isVisible = false
                    casMissionDialog.close()
                }
            }

            Timer {
                id: takeoffTimer
                interval:1500
                running:true
                repeat: false
                onTriggered: {

                    console.log("Armd Triggered >>>>>>>>>>")
                    casMissionDialog.vehicle.sendCommand(
                        1,
                        22,
                        true,
                        0,0,0,0,
                        casMissionDialog.vehicle.latitude,
                        casMissionDialog.vehicle.longitude,
                        10.0
                        )
                    loiterTimer.start()
                }
            }

            Timer {
                id: loiterTimer
                interval:25000
                running:true
                repeat: false
                onTriggered: {
           console.log("Loitering Triggered >>>>>>>>>>")
                      vehicle.sendCommand(
                        1,    // e.g., 1
                        202,                 // MAV_CMD_LOITER_TURNS
                        true,                // confirmation
                        3,                   // param1: number of turns
                        20,                  // param2: radius in meters
                        0,                   // param3: reserved
                        0,                   // param4: reserved
                        10,                   // param5: latitude (0 = current)
                        10,                   // param6: longitude (0 = current)
                        10                   // param7: altitude relative to home
                    );
                }
            }




            Button {
                text: qsTr("Send CAS Mission")
                enabled: approachAltField.text && coordinateField.text && egressAltField.text
                onClicked: {

                    console.log("heading >>>> ", headingBox.currentText, headingBox.currentIndex)
                    console.log("approachAlt >>>> ", approachAltField.text)
                    console.log("coordinate >>>> ", coordinateField.text)
                    console.log("coordinate Format >>>> ", coordinateFormat)
                    console.log("EgressDirection >>>> ", egressBox.currentText, egressBox.currentIndex)
                    console.log("Egress Alt >>>> ", egressAltField.text)

                    casMissionDialog.isVisible = false
                    casMissionDialog.close()

                    casMissionDialog.vehicle.flightMode = "GUIDED"    // set Guide as Mode

                    // Arm vehicle
                    casMissionDialog.vehicle.sendCommand(
                        1,      // target system ID (usually 1)
                        400,    // MAV_CMD_COMPONENT_ARM_DISARM
                        true,   // confirmation
                        1,      // param1: 1 to arm, 0 to disarm
                        0,      // param2: 0 for normal arm, 21196 for force arm
                        0,      // param3
                        0,      // param4
                        0,      // param5
                        0,      // param6
                        0       // param7
                    );

                    takeoffTimer.start()

                    casMissionDialog.vehicle.sendCommand(
                        1,
                        31010,
                        true,
                        headingBox.currentIndex,     // heading
                        approachAltField.text,     // approach altitude
                        coordinateFormat, // Coordinate Format
                        coordinateField.text, // Coordinate Value
                        egressBox.currentIndex,    // egress direction
                        egressAltField.text      // egress altitude
                    )
                }
            }
        }
    }
}


// import QtQuick
// import QtQuick.Controls
// // import QtQuick.Layouts


// Dialog {
//     id: casMissionDialog
//     title: "CAS Mission"
//     modal: true
//     standardButtons: Dialog.Ok | Dialog.Cancel

//     onAccepted: casMissionDialog.close()
//     onRejected: casMissionDialog.close()

//     Text {
//         text: "This is the CAS Mission dialog."
//         anchors.centerIn: parent
//     }
// }

