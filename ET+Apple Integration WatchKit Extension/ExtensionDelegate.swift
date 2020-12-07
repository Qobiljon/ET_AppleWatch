import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        // App launched --> make final initializations
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("wc activated")
        } else {
            print("wc not supported")
        }
        
        ETwatchOSTools.scheduleNextBGDataSubmissionTask()
        ETCoreMotion.getInstance()?.startAccelerometerAcquisition()
        ETCoreMotion.getInstance()?.startDeviceMotionAcquisition()
        ETHealthKit.getInstance()?.startHealthKitAcquisition()
    }
    func applicationDidBecomeActive() {
        // Moved from inactive to active state --> restart any tasks that were paused / not started, refresh ui
        
        ETwatchOSTools.scheduleNextBGDataSubmissionTask()
        ETCoreMotion.getInstance()?.startAccelerometerAcquisition()
        ETCoreMotion.getInstance()?.startDeviceMotionAcquisition()
        ETHealthKit.getInstance()?.startHealthKitAcquisition()
    }
    func applicationWillResignActive() {
        // About to move from active to inactive state (e.g., phone call, SMS, quit the app and transition to background state) --> pause ongoing tasks
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        ETwatchOSTools.scheduleNextBGDataSubmissionTask()
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                ETCoreMotion.getInstance()?.startAccelerometerAcquisition()
                ETCoreMotion.getInstance()?.startDeviceMotionAcquisition()
                ETHealthKit.getInstance()?.startHealthKitAcquisition()
                ETwatchOSTools.submitDataWc()
                
                print("handle() backgroundTask function call")
                backgroundTask.setTaskCompletedWithSnapshot(false)
            default:
                // Make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}

extension ExtensionDelegate : WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        switch activationState {
        case .activated:
            print("wcSession activated")
            break
        case .inactive:
            print("wcSession activated")
            break
        case .notActivated:
            print("wcSession not activated")
            break
        default:
            break
        }
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let action = message["action"] {
            switch action as! String {
            case "submitFiles":
                ETwatchOSTools.submitDataWc()
                break
            case "removeFile":
                if let fileName = message["fileName"], let submissionFile = ETwatchOSSubmissionFile.getInstance(fileName: fileName as! String) {
                    do {
                        try submissionFile.removeFile()
                    } catch {
                        print("error removing file \(fileName), error=\(error)")
                    }
                }
                break
            default:
                break
            }
        }
    }
    
    private func wcReplyHandler(message: [String:Any]) {
        print("ExtensionDelegate.wcReplyHandler \(message)")
    }
    private func wcErrorHandler(error: Error) {
        print("ExtensionDelegate.wcErrorHandler \(error)")
    }
}
