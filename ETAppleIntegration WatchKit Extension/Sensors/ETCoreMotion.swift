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
        guard let accelerometerData = accelerometerData else { return }
        if error != nil {
            print("accelerometer error")
        } else {
            // print("accelerometer event")
            ETSensor.submitData(
                dataSourceId: 55,
                timestamp: Int64(Date(timeInterval: accelerometerData.timestamp, since: ETSensor.bootTime).timeIntervalSince1970 * 1000),
                value: "\(accelerometerData.acceleration.x),\(accelerometerData.acceleration.y),\(accelerometerData.acceleration.z)".data(using: .utf8)!
            )
        }
    }
    private func deviceMotionHandler(deviceMotion:CMDeviceMotion?, error: Error?) {
        guard let deviceMotion = deviceMotion else { return }
        if error != nil {
            print("deviceMotion error")
        } else {
            // print("device motion event")
            var strValue = "\(deviceMotion.attitude.pitch),\(deviceMotion.attitude.roll),\(deviceMotion.attitude.yaw)"
            strValue.append(",\(deviceMotion.heading)")
            strValue.append(",\(deviceMotion.gravity)")
            strValue.append(",\(deviceMotion.magneticField.field.x),\(deviceMotion.magneticField.field.y),\(deviceMotion.magneticField.field.z),\(deviceMotion.magneticField.accuracy.rawValue)")
            strValue.append(",\(deviceMotion.rotationRate.x),\(deviceMotion.rotationRate.y),\(deviceMotion.rotationRate.z)")
            strValue.append(",\(deviceMotion.userAcceleration.x),\(deviceMotion.userAcceleration.y),\(deviceMotion.userAcceleration.z)")
            strValue.append(",\(deviceMotion.sensorLocation.rawValue)")
            
            ETSensor.submitData(
                dataSourceId: 54,
                timestamp: Int64(Date(timeInterval: deviceMotion.timestamp, since: ETSensor.bootTime).timeIntervalSince1970 * 1000),
                value: strValue.data(using: .utf8)!
            )
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
    func stopAccelerometer() {
        if motionManager.isAccelerometerActive {
            motionManager.stopAccelerometerUpdates()
        }
    }
    
    func startDeviceMotion() -> Bool {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 1.0
            motionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: deviceMotionHandler)
            return true
        }
        return false
    }
    func stopDeviceMotion() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
    
    func startSensing() -> Bool {
        let acc = startAccelerometer()
        let dmo = startDeviceMotion()
        return acc && dmo
    }
    func stopSensing() {
        stopAccelerometer()
        stopDeviceMotion()
    }
}
