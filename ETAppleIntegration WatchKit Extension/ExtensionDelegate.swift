import WatchKit


class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
    }
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        if ETTools.health.isHealthKitUnauthorized() {
            ETTools.health.requestHealthKitAuthorization{ (success, error) in
                if error == nil {
                    ETTools.motion.startAccelerometer()
                    ETTools.motion.startDeviceMotion()
                    ETTools.health.requestHealthKitData()
                    print("authorization request success=\(success)")
                } else {
                    print("authorization request error \(error!)")
                }
            }
        } else {
            ETTools.motion.startAccelerometer()
            ETTools.motion.startDeviceMotion()
            ETTools.health.requestHealthKitData()
        }
    }
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        ETTools.scheduleNextBGDataSubmissionTask()
    }
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                ETTools.motion.startAccelerometer()
                ETTools.motion.startDeviceMotion()
                ETTools.health.requestHealthKitData()
                ETTools.scheduleNextBGDataSubmissionTask()
                backgroundTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
