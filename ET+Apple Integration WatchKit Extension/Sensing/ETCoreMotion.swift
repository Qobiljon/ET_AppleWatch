import Foundation
import CoreMotion


let DEVICE_MOTION_DATA_SOURCE_ID = Int32(54)
let ACCELEROMETER_DATA_SOURCE_ID = Int32(55)

class ETCoreMotion {
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    
    
    // singleton
    private static var instance: ETCoreMotion?
    static func getInstance() -> ETCoreMotion? {
        if instance == nil {
            instance = ETCoreMotion()
        }
        return instance
    }
    private init() {}
    
    
    private func accelerometerHandler(accelerometerData:CMAccelerometerData?, error: Error?) {
        if error != nil {
            print("accelerometer error")
        } else {
            guard let accelerometerData = accelerometerData else { return }
            guard let acquisitionFile = ETwatchOSAcquisitionFile.getInstance() else { return }
            
            let dataSourceId = ACCELEROMETER_DATA_SOURCE_ID
            let timestamp = Int64(Date(timeInterval: accelerometerData.timestamp, since: ETwatchOSTools.bootTime).timeIntervalSince1970 * 1000)
            let value = "\(accelerometerData.acceleration.x),\(accelerometerData.acceleration.y),\(accelerometerData.acceleration.z)"
            
            do {
                try acquisitionFile.storeDataSample(
                    dataSourceId: dataSourceId,
                    timestamp: timestamp,
                    value: value
                )
            } catch {
                print("error storing accelerometer data sample \(error)")
            }
        }
    }
    private func deviceMotionHandler(deviceMotion:CMDeviceMotion?, error: Error?) {
        if error != nil {
            print("deviceMotion error")
        } else {
            guard let deviceMotion = deviceMotion else { return }
            guard let acquisitionFile = ETwatchOSAcquisitionFile.getInstance() else { return }
            
            let dataSourceId = DEVICE_MOTION_DATA_SOURCE_ID
            let timestamp = Int64(Date(timeInterval: deviceMotion.timestamp, since: ETwatchOSTools.bootTime).timeIntervalSince1970 * 1000)
            var value = "\(deviceMotion.attitude.pitch),\(deviceMotion.attitude.roll),\(deviceMotion.attitude.yaw)"
            value.append(",\(deviceMotion.heading)")
            value.append(",\(deviceMotion.gravity)")
            value.append(",\(deviceMotion.magneticField.field.x),\(deviceMotion.magneticField.field.y),\(deviceMotion.magneticField.field.z),\(deviceMotion.magneticField.accuracy.rawValue)")
            value.append(",\(deviceMotion.rotationRate.x),\(deviceMotion.rotationRate.y),\(deviceMotion.rotationRate.z)")
            value.append(",\(deviceMotion.userAcceleration.x),\(deviceMotion.userAcceleration.y),\(deviceMotion.userAcceleration.z)")
            value.append(",\(deviceMotion.sensorLocation.rawValue)")
            
            do {
                try acquisitionFile.storeDataSample(
                    dataSourceId: dataSourceId,
                    timestamp: timestamp,
                    value: value
                )
            } catch {
                print("error storing device motion data sample \(error)")
            }
        }
    }
    
    func startAccelerometerAcquisition() {
        if self.motionManager.isAccelerometerAvailable && !self.motionManager.isAccelerometerActive {
            self.motionManager.accelerometerUpdateInterval = 1.0 / 1.0
            self.motionManager.startAccelerometerUpdates(to: operationQueue, withHandler: accelerometerHandler)
        }
    }
    func stopAccelerometerAcquisition() {
        if self.motionManager.isAccelerometerActive {
            self.motionManager.stopAccelerometerUpdates()
        }
    }
    func startDeviceMotionAcquisition() {
        if self.motionManager.isDeviceMotionAvailable && !self.motionManager.isDeviceMotionActive {
            self.motionManager.deviceMotionUpdateInterval = 1.0 / 1.0
            self.motionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: deviceMotionHandler)
        }
    }
    func stopDeviceMotionAcquisition() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
    }
}
