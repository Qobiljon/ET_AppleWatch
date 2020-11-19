import Foundation
import GRPC
import NIO

class ETSensor {
    public static let motion = ETCoreMotion()
    public static let health = ETHealthKit()
    private static var channel: ClientConnection?
    
    private static func getChannel() -> ClientConnection {
        if ETSensor.channel != nil && ETSensor.channel?.connectivity.state == ConnectivityState.ready {
            return ETSensor.channel!
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        ETSensor.channel = ClientConnection.insecure(group: group).connect(host: "165.246.42.173", port: 50051)
        return ETSensor.channel!
    }
    
    static var done = false
    public static func submitData(dataSourceId: Int32, timestamp: Int64, value: Data) {
        if done {
            return
        } else {
            done = true
        }
        
        // get a channel
        let channel = getChannel()
        let client = ETServiceClient(channel: channel)
        print("GRPC ==> connection established")
        
        // call rpc
        let request = SubmitDataRecord.Request.with{
            $0.userID = 66
            $0.email = "nslabinha@gmail.com"
            $0.campaignID = 5
            $0.timestamp = timestamp
            $0.dataSource = dataSourceId
            $0.accuracy = 1.0
            $0.value = value
        }
        let rpc = client.submitDataRecord(request)
        print("GRPC ==> rpc called")
        
        rpc.response.whenSuccess { result in print("GRPC ==> success \(result.success)") }
        rpc.response.whenFailure { error in print("GRPC ==> error \(error)") }
    }
}
