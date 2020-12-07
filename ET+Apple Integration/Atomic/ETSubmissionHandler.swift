import Foundation
import Dispatch
import GRPC
import Network
import NIO


private let ET_USER_ID = Int32(1)
private let ET_CAMPAIGN_ID = Int32(1)
private let ET_GRPC_HOST = "165.246.21.202"
private let ET_GRPC_PORT = 50051

class ETgRPCSubmission {
    private let queue = DispatchQueue(label: "grpc-submission-queue")
    private var schedulerThread: Thread?
    private var batchDone = true
    
    // singleton
    private static var instance: ETgRPCSubmission?
    static func getInstance() -> ETgRPCSubmission? {
        if instance == nil {
            instance = ETgRPCSubmission()
        }
        return instance
    }
    private init() {}
    
    
    func trigger() {
        if schedulerThread?.isExecuting == true {
            return
        } else {
            schedulerThread = Thread {
                while true {
                    do {
                        let submissionFileNames = try ETiOSSubmissionFile.listSubmissionFileNames()
                        print("-*-*- \(submissionFileNames.count) submit jobs -*-*-")
                        
                        for fileName in submissionFileNames {
                            if let file = ETiOSSubmissionFile.getInstance(fileName: fileName) {
                                let tuple = try file.readBatchContentForGrpc()
                                
                                let dataSourceIds = tuple.0
                                let timestamps = tuple.1
                                let values = tuple.2
                                
                                self.queue.sync {
                                    while !self.batchDone {
                                        Thread.sleep(forTimeInterval: 0.1)
                                    }
                                    self.batchDone = false
                                    self.submitBatchGrpc(dataSourceIds: dataSourceIds, timestamps: timestamps, values: values, file: file)
                                }
                            }
                        }
                    } catch {
                        print("data submission error \(error)")
                    }
                    
                    ETiOSTools.requestDataWc()
                    Thread.sleep(forTimeInterval: 60.0) // 1 minute
                }
            }
            schedulerThread!.start()
        }
    }
    
    private func submitBatchGrpc(dataSourceIds: [Int32], timestamps: [Int64], values: [Data], file: ETiOSSubmissionFile) {
        // prepare the request
        var accuracies: [Float] = []
        for _ in 0..<timestamps.count {
            accuracies.append(1.0)
        }
        let request = SubmitDataRecords.Request.with{
            $0.userID = ET_USER_ID
            $0.email = "nslabinha@gmail.com"
            $0.campaignID = ET_CAMPAIGN_ID
            $0.timestamp = timestamps
            $0.dataSource = dataSourceIds
            $0.accuracy = accuracies
            $0.value = values
        }
        
        // prepare grpc stub
        let connection = ClientConnection(configuration: ClientConnection.Configuration(
            target: .hostAndPort(ET_GRPC_HOST, ET_GRPC_PORT),
            eventLoopGroup: PlatformSupport.makeEventLoopGroup(loopCount: 1)
        ))
        let stub = ETServiceClient(channel: connection)
        let rpc = stub.submitDataRecords(request)
        print("GRPC ==> rpc call")
        
        rpc.response.whenSuccess { result in
            print("GRPC ==> success \(result.success)")
            self.batchDone = true
            do {
                let _ = connection.close()
                try file.removeFile()
                print("submission file submitted and removed")
            } catch {
                print("error removing a submission file \(error)")
            }
        }
        rpc.response.whenFailure { error in
            print("GRPC ==> error \(error)")
            self.batchDone = true
            let _ = connection.close()
        }
    }
}
