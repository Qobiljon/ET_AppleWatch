import WatchKit


class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        // App launched --> make final initializations
    }
    func applicationDidBecomeActive() {
        // Moved from inactive to active state --> restart any tasks that were paused / not started, refresh ui
        guard let coreMotion = ETCoreMotion.getInstance() else { return }
        guard let healthKit = ETHealthKit.getInstance() else { return }
        guard let submission = ETSubmission.getInstance() else { return }
        
        coreMotion.startAccelerometerAcquisition()
        coreMotion.startDeviceMotionAcquisition()
        healthKit.startHealthKitAcquisition()
        submission.trigger()
        ETTools.scheduleNextBGDataSubmissionTask()
    }
    func applicationWillResignActive() {
        // About to move from active to inactive state (e.g., phone call, SMS, quit the app and transition to background state) --> pause ongoing tasks
        ETTools.scheduleNextBGDataSubmissionTask()
    }
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                guard let coreMotion = ETCoreMotion.getInstance() else { return }
                guard let healthKit = ETHealthKit.getInstance() else { return }
                guard let submission = ETSubmission.getInstance() else { return }
                
                coreMotion.startAccelerometerAcquisition()
                coreMotion.startDeviceMotionAcquisition()
                healthKit.startHealthKitAcquisition()
                submission.trigger()
                ETTools.scheduleNextBGDataSubmissionTask()
                backgroundTask.setTaskCompletedWithSnapshot(false)
            default:
                // Make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
