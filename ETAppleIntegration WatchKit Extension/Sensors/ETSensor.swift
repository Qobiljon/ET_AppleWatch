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
    
    public static func submitData(dataSourceId: Int32, timestamp: Int64, value: Data) {
        // get a channel
        let channel = getChannel()
        let client = ETServiceClient(channel: channel)
        
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
        
        rpc.response.whenSuccess { result in
            if !result.success {
                print("grpc success = false")
            }
        }
        rpc.response.whenFailure { error in
            print("grpc error \(error)")
        }
    }
}
