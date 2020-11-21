import Foundation
import Dispatch
import GRPC
import Network


private let ET_USER_ID = Int32(66)
private let ET_CAMPAIGN_ID = Int32(5)
private let ET_GRPC_HOST = "165.246.42.173"
private let ET_GRPC_PORT = 50051

class ETSubmission {
    private let queue = DispatchQueue(label: "grpc-submission-queue")
    private var schedulerThread: Thread?
    private var batchDone = true
    private var canDelete = false
    
    
    // singleton
    private static var instance: ETSubmission?
    static func getInstance() -> ETSubmission? {
        if instance == nil {
            instance = ETSubmission()
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
                        if let acquisitionFile = ETAcquisitionFile.getInstance() {
                            try acquisitionFile.moveContentToBatchFiles()
                            let submissionFileNames = try ETSubmissionFile.listSubmissionFileNames()
                            print("\(submissionFileNames.count) submit jobs : \(submissionFileNames)")
                            
                            for fileName in submissionFileNames {
                                if let file = ETSubmissionFile.getInstance(fileName: fileName) {
                                    let tuple = try file.readBatchContent()
                                    
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
    private func submitBatchGrpc(dataSourceIds: [Int32], timestamps: [Int64], values: [Data], file: ETSubmissionFile) {
        // call rpc
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
                try file.removeFile()
            } catch {
                print("error removing a submission file \(error)")
            }
        }
        rpc.response.whenFailure { error in
            print("GRPC ==> error \(error)")
            self.batchDone = true
        }
    }
}
