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
        defer {
            try! group.syncShutdownGracefully()
        }
        
        ETSensor.channel = ClientConnection.insecure(group: group).connect(host: "165.246.42.173", port: 50051)
        return ETSensor.channel!
    }
    
    public static func submitData(dataSourceId: Int32, timestamp: Int64, value: Data) {
        // get a channel
        let channel = getChannel()
        
        // perform an RPC
        let client = ETServiceClient(channel: channel)
        let rpc = client.submitDataRecord(.with{
            $0.userID = 1
            $0.email = "nslabinha@gmail.com"
            $0.campaignID = 5 // tbd change
            
            $0.timestamp = timestamp
            $0.dataSource = dataSourceId
            $0.accuracy = 1.0
            $0.value = value
        })
        rpc.response.whenSuccess { response in
            print("gRPC success \(response.success)")
        }
        rpc.response.whenFailure { error in
            print("gRPC error \(error)")
        }
    }
}
