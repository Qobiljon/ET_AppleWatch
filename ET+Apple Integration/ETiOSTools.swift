import Foundation
import WatchConnectivity


class ETiOSTools {
    // constants
    static let bootTime = Date(timeIntervalSinceNow: -ProcessInfo.processInfo.systemUptime)
    
    // others
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
    static func requestDataWc() {
        if WCSession.default.isPaired && WCSession.default.isReachable && WCSession.default.isWatchAppInstalled {
            WCSession.default.sendMessage([
                "action": "submitFiles"
            ], replyHandler: wcReplyHandler, errorHandler: wcErrorHandler)
        }
    }
    static func fileExists(fileName: String) -> Bool {
        guard let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            return false
        }
        let fileUrl = documentsUrl.appendingPathComponent(fileName, isDirectory: false)
        return FileManager.default.fileExists(atPath: fileUrl.path)
    }
}

extension ETiOSTools {
    private static func wcReplyHandler(message: [String:Any]) {
        print("ETiOSTools.wcReplyHandler \(message)")
    }
    private static func wcErrorHandler(error: Error) {
        print("ETiOSTools.wcErrorHandler \(error)")
    }
}
