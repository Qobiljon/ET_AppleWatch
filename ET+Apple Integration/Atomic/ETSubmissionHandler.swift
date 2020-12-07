import Foundation
import Dispatch
import GRPC
import Network
import NIO


private let ET_USER_ID = Int32(66)
private let ET_CAMPAIGN_ID = Int32(5)
private let ET_GRPC_HOST = "165.246.42.173"
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
                        if let acquisitionFile = ETiOSAcquisitionFile.getInstance() {
                            try acquisitionFile.moveContentToBatchFiles()
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
                        }
                    } catch {
                        print("data submission error \(error)")
                    }
                    
                    Thread.sleep(forTimeInterval: 10.0) // 1 minute
                }
            }
            schedulerThread!.start()
        }
    }
    private func submitBatchGrpc(dataSourceIds: [Int32], timestamps: [Int64], values: [Data], file: ETiOSSubmissionFile) {
        /*// Create an `EventLoopGroup`.
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        // Create a channel.
        let channel = ClientConnection.secure(group: group)
            // We're connecting to our own server here; we'll disable connection re-establishment.
            .withConnectionReestablishment(enabled: false)
            .withConnectionTimeout(minimum: TimeAmount.milliseconds(100))
            .withConnectionBackoff(maximum: TimeAmount.seconds(2))
            // Connect!
            .connect(host: ET_GRPC_HOST, port: ET_GRPC_PORT)
        
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
        let client = ETServiceClient(channel: channel)
        let rpc = client.submitDataRecords(request)
        print("GRPC ==> rpc call")
        rpc.response.whenSuccess { result in
            print("GRPC ==> success \(result.success)")
            self.batchDone = true
            do {
                let _ = channel.close()
                try file.removeFile()
                print("submission file submitted and removed")
            } catch {
                print("error removing a submission file \(error)")
            }
        }
        rpc.response.whenFailure { error in
            print("GRPC ==> error \(error)")
            self.batchDone = true
            let _ = channel.close()
        }*/
    }
}
