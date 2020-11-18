import Foundation
import CoreMotion


class ETCoreMotion {
    // variables
    private let motionManager: CMMotionManager!
    private let operationQueue: OperationQueue!
    
    
    // init function
    init() {
        self.motionManager = CMMotionManager()
        self.operationQueue = OperationQueue()
    }
    
    
    // sensor handlers (event listeners)
    private func accelerometerHandler(accelerometerData:CMAccelerometerData?, error: Error?) {
        guard let _ = accelerometerData else { return }
        if error != nil {
            print("accelerometer error")
        } else {
            print("accelerometer event")
        }
    }
    private func deviceMotionHandler(deviceMotion:CMDeviceMotion?, error: Error?) {
        guard let _ = deviceMotion else { return }
        if error != nil {
            print("deviceMotion error")
        } else {
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
