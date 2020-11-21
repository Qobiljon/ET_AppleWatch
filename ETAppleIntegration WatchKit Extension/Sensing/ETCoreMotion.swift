import Foundation
import CoreMotion


class ETCoreMotion {
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    private func accelerometerHandler(accelerometerData:CMAccelerometerData?, error: Error?) {
        guard let accelerometerData = accelerometerData else { return }
        if error != nil {
            print("accelerometer error")
        } else {
            // print("accelerometer event")
            ETTools.storeData(
                dataSourceId: ETTools.ACCELEROMETER_DATA_SOURCE_ID,
                timestamp: Int64(Date(timeInterval: accelerometerData.timestamp, since: ETTools.bootTime).timeIntervalSince1970 * 1000),
                value: "\(accelerometerData.acceleration.x),\(accelerometerData.acceleration.y),\(accelerometerData.acceleration.z)"
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
            
            ETTools.storeData(
                dataSourceId: ETTools.DEVICE_MOTION_DATA_SOURCE_ID,
                timestamp: Int64(Date(timeInterval: deviceMotion.timestamp, since: ETTools.bootTime).timeIntervalSince1970 * 1000),
                value: strValue
            )
        }
    }
    
    func startAccelerometer() {
        if self.motionManager.isAccelerometerAvailable && !self.motionManager.isAccelerometerActive {
            self.motionManager.accelerometerUpdateInterval = 1.0 / 1.0
            self.motionManager.startAccelerometerUpdates(to: operationQueue, withHandler: accelerometerHandler)
        }
    }
    func stopAccelerometer() {
        if self.motionManager.isAccelerometerActive {
            self.motionManager.stopAccelerometerUpdates()
        }
    }
    func startDeviceMotion() {
        if self.motionManager.isDeviceMotionAvailable && !self.motionManager.isDeviceMotionActive {
            self.motionManager.deviceMotionUpdateInterval = 1.0 / 1.0
            self.motionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: deviceMotionHandler)
        }
    }
    func stopDeviceMotion() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}
