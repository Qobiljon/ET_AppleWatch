import Foundation
import WatchKit
import WatchConnectivity


class ETwatchOSTools {
    // constants
    static let bootTime = Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
    
    // others
    static func scheduleNextBGDataSubmissionTask() {
        let fireDate = Date(timeIntervalSinceNow: 60) // 1 minute
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: nil) { (error) in
            if error == nil {
                print("bg task scheduled \(DateFormatter.localizedString(from: fireDate, dateStyle: .short, timeStyle: .medium))")
            } else {
                print("bg task schedule error \(error!)")
            }
        }
    }
    static func splitToBatches<T>(array: [T], batchSize: Int) -> [[T]] {
        if batchSize < 1 {
            return [[]]
        }
        var res: [[T]] = []
        var index = 0
        while index < array.count {
            let nextJump = min(index + batchSize, array.count)
            res += [Array<T>(array[index..<nextJump])]
            index += batchSize
        }
        return res
    }
    static func submitDataWc() {
        if let acquisitionFile = ETwatchOSAcquisitionFile.getInstance() {
            do {
                try acquisitionFile.moveContentToBatchFiles()
            } catch {
                print("failed to split acquisition file into batches \(error)")
            }
            
            do {
                let submissionFileNames = try ETwatchOSSubmissionFile.listSubmissionFileNames()
                if submissionFileNames.count == 0 {
                    print("no submission file available, skipping wc submission this time")
                } else {
                    print("\(submissionFileNames.count) submit jobs : \(submissionFileNames)")
                    
                    for fileName in submissionFileNames {
                        if let file = ETwatchOSSubmissionFile.getInstance(fileName: fileName) {
                            let batchContent = try file.readBatchContentForWc()
                            WCSession.default.sendMessage([
                                "batchContent": batchContent,
                                "fileName": fileName,
                            ], replyHandler: wcReplyHandler, errorHandler: wcErrorHandler)
                        }
                    }
                }
            } catch {
                print("failed to make a list submission files \(error)")
            }
        } else {
            print("failed to get acquisition file")
        }
    }
}

extension ETwatchOSTools {
    private static func wcReplyHandler(message: [String:Any]) {
        print("ETwatchOSTools.wcReplyHandler \(message)")
    }
    private static func wcErrorHandler(error: Error) {
        print("ETwatchOSTools.wcErrorHandler \(error)")
    }
}
