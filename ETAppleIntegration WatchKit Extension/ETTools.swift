import Foundation
import WatchKit


class ETTools {
    // constants
    static let bootTime = Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
    
    // others
    static func scheduleNextBGDataSubmissionTask() {
        let fireDate = Date(timeIntervalSinceNow: 60) // 1 minute
        WKExtension.shared().scheduleBackgroundRefresh(withPreferredDate: fireDate, userInfo: nil) { (error) in
            if error == nil {
                print("bg task scheduled \(fireDate)")
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
}
