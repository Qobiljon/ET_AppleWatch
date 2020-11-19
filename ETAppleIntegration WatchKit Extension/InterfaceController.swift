import Foundation
import WatchKit


class InterfaceController: WKInterfaceController {
    // variables
    @IBOutlet var startButton : WKInterfaceButton!
    @IBOutlet var stopButton : WKInterfaceButton!
    
    
    // override functions
    override func awake(withContext context: Any?) {
        // ui awake
    }
    override func willActivate() {
        // watch view controller is about to be visible to user
    }
    override func didDeactivate() {
        // watch view controller is no longer visible
    }
    
    
    // ui event handlers
    @IBAction func startClick() {
        // start sensing
        if /* ETSensor.motion.startSensing() && */ ETSensor.health.startSensing() {
            // ui changes
            startButton.setEnabled(false)
            startButton.setBackgroundColor(UIColor.gray)
            stopButton.setEnabled(true)
            stopButton.setBackgroundColor(UIColor.purple)
        }
    }
    @IBAction func stopClick() {
        // stop sensing
        ETSensor.motion.stopSensing()
        ETSensor.health.stopSensing()
        
        // ui changes
        startButton.setEnabled(true)
        startButton.setBackgroundColor(UIColor.blue)
        stopButton.setEnabled(false)
        stopButton.setBackgroundColor(UIColor.gray)
    }
    @IBAction func testClick() {
        let dataSourceId = Int32(63) // HR
        let timestamp = Int64(1605773847000)
        let value = "65 count/min".data(using: .utf8)!
        
        ETSensor.submitData(
            dataSourceId: dataSourceId,
            timestamp: timestamp,
            value: value
        )
    }
}
