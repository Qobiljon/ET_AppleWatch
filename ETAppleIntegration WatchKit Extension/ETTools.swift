import Foundation
import Dispatch
import HealthKit
import GRPC
import WatchKit


extension String {
    func appendLineToURL(fileURL: URL) throws {
        try (self + "\n").appendToURL(fileURL: fileURL)
    }
    func appendToURL(fileURL: URL) throws {
        let data = self.data(using: String.Encoding.utf8)!
        try data.append(fileURL: fileURL)
    }
}
extension Data {
    func append(fileURL: URL) throws {
        if let fileHandle = FileHandle(forWritingAtPath: fileURL.path) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

class ETTools {
    // EasyTrack constants
    static let DEVICE_MOTION_DATA_SOURCE_ID = Int32(54)
    static let ACCELEROMETER_DATA_SOURCE_ID = Int32(55)
    private static let ET_USER_ID = Int32(66)
    private static let ET_CAMPAIGN_ID = Int32(5)
    private static let ET_GRPC_HOST = "165.246.42.173"
    private static let ET_GRPC_PORT = 50051
    // other constants
    static let bootTime = Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
    static let motion = ETCoreMotion()
    static let health = ETHealthKit()
    private static let submitQueue = DispatchQueue(label: "thread-safe-obj", attributes: .concurrent)
    private static let fileManager = FileManager()
    private static var fileUrl: URL?
    // variables
    private static var connection: ClientConnection?
    
    
    // ET gRPC functions
    static func getGrpcChannel() -> ClientConnection? {
        if connection?.connectivity.state == ConnectivityState.ready {
            return connection
        } else {
            do {
                try connection?.close().wait()
            } catch {
                print("error closing invalid connection \(error)")
            }
            connection = nil
        }
        connection = ClientConnection(configuration: ClientConnection.Configuration(
            target: .hostAndPort(ET_GRPC_HOST, ET_GRPC_PORT),
            eventLoopGroup: PlatformSupport.makeEventLoopGroup(loopCount: 1)
        ))
        return connection
    }
    static func submitData(dataSourceId: Int32, timestamp: Int64, value: Data) {
        print("--- data source id = \(dataSourceId)")
        // get a channel
        /*guard let channel = getGrpcChannel() else {
         print("gRPC channel creation error")
         return
         }
         let client = ETServiceClient(channel: channel)
         
         // call rpc
         let request = SubmitDataRecord.Request.with{
         $0.userID = ET_USER_ID
         $0.email = "nslabinha@gmail.com"
         $0.campaignID = ET_CAMPAIGN_ID
         $0.timestamp = timestamp
         $0.dataSource = dataSourceId
         $0.accuracy = 1.0
         $0.value = value
         }
         let rpc = client.submitDataRecord(request)
         
         print("GRPC ==> rpc call")
         rpc.response.whenSuccess { result in
         print("GRPC ==> success \(result.success)")
         }
         rpc.response.whenFailure { error in
         print("GRPC ==> error \(error)")
         }*/
    }
    // HealthKit functions
    private static func getHKDataSourceMap() -> [HKObjectType : Int32] {
        return [
            // activity
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)! : 70,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)! : 69,
            HKQuantityType.quantityType(forIdentifier: .appleStandTime)! : 68,
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)! : 67,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)! : 66,
            
            // hearing
            HKQuantityType.quantityType(forIdentifier: .environmentalAudioExposure)! : 65,
            HKQuantityType.quantityType(forIdentifier: .headphoneAudioExposure)! : 64,
            
            // heart (vital)
            HKQuantityType.quantityType(forIdentifier: .heartRate)! : 63,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)! : 62,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)! : 61,
            HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage)! : 60,
            
            // mobility
            HKQuantityType.quantityType(forIdentifier: .stepCount)! : 59,
            HKQuantityType.quantityType(forIdentifier: .walkingSpeed)! : 58,
            HKQuantityType.quantityType(forIdentifier: .walkingStepLength)! : 57,
            
            // other data
            HKQuantityType.quantityType(forIdentifier: .numberOfTimesFallen)! : 56,
        ]
    }
    static func getHKDataTypes() -> [HKObjectType] {
        return Array(getHKDataSourceMap().keys)
    }
    static func getHKDataSourceId(objectType: HKObjectType) -> Int32 {
        let res = getHKDataSourceMap()[objectType]
        if res == nil {
            return Int32(-1)
        } else {
            return res!
        }
    }
    // others
    static func scheduleNextBGDataSubmissionTask() {
        let fireDate = Date(timeIntervalSinceNow: 10) // 10 seconds
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: nil) { (error) in
            if error == nil {
                print("bg task scheduled \(fireDate)")
            } else {
                print("bg task schedule error \(error!)")
            }
        }
    }
    static func bindDataFile() -> URL? {
        // check if already bound
        if fileUrl != nil {
            return fileUrl
        }
        
        // chek if there is access to documents dir (path)
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        guard let tmpFileUrl = documentsUrl?.appendingPathComponent("data.csv", isDirectory: false) else {
            return nil
        }
        
        // create file if file doesn't exist
        if !fileManager.fileExists(atPath: tmpFileUrl.path) {
            let success = fileManager.createFile(
                atPath: tmpFileUrl.path,
                contents: "".data(using: .utf8),
                attributes: nil
            )
            print("data file creation success=\(success)")
        }
        
        // bind file descriptor
        if fileManager.fileExists(atPath: tmpFileUrl.path) {
            ETTools.fileUrl = tmpFileUrl
        }
        
        // return the result
        return ETTools.fileUrl
    }
    static func storeData(dataSourceId: Int32, timestamp: Int64, value: String) {
        guard let fileUrl = bindDataFile() else {
            print("error - nowhere to write")
            return // nowhere to store
        }
        
        do {
            try "\(timestamp),\(dataSourceId),\(value)".appendToURL(fileURL: fileUrl)
            print("\(dataSourceId) line written successfully")
        } catch {
            print("store data error \(error)")
        }
    }
}
