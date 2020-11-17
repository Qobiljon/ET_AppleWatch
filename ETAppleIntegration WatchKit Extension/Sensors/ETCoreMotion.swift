import Foundation
import CoreMotion

class ETCoreMotion {
    // variables
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    
    // sensor handlers (event listeners)
    private func accelerometerHandler(accelerometerData:CMAccelerometerData?, error: Error?) {
        if error != nil {
            print("accelerometer error")
        } else if accelerometerData != nil {
            // let timestamp = data.timestamp.magnitude
            // let acceleration = data.acceleration
            print("accelerometer event")
        }
    }
    private func deviceMotionHandler(deviceMotion:CMDeviceMotion?, error: Error?) {
        if error != nil {
            print("deviceMotion error")
        } else if deviceMotion != nil {
            print("device motion event")
        }
    }
    
    
    // sensor start/stop functions
    func startAccelerometer() -> Bool {
        if motionManager.isDeviceMotionAvailable {
            motionManager.accelerometerUpdateInterval = 1.0 / 1.0
            motionManager.startAccelerometerUpdates(to: operationQueue, withHandler: accelerometerHandler)
            return true
        }
        return false
    }
    func stopAccelerometer() -> Bool {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
            return true
        }
        return false
    }
    
    func startDeviceMotion() -> Bool {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 1.0
            motionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: deviceMotionHandler)
            return true
        }
        return false
    }
    func stopDeviceMotion() -> Bool {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
            return true
        }
        return false
    }
    
    func startSensing() -> Bool {
        let acc = startAccelerometer()
        let dmo = startDeviceMotion()
        return acc && dmo
    }
    func stopSensing() -> Bool {
        let acc = stopAccelerometer()
        let dmo = stopDeviceMotion()
        return acc && dmo
    }
}
