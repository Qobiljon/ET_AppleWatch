import UIKit
import WatchConnectivity

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
            print("wc activated")
        } else {
            print("wc not supported")
        }
        
        if let submission = ETgRPCSubmission.getInstance() {
            submission.trigger()
        }
        
        return true
    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created. Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate : WCSessionDelegate {
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("sessionDidBecomeInactive")
    }
    func sessionDidDeactivate(_ session: WCSession) {
        print("sessionDidDeactivate")
    }
    
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
        if let batchContent = message["batchContent"], let fileName = message["fileName"] {
            print("batch \(fileName as! String) received \((batchContent as! String).count)")
            
            do {
                // save the data locally
                try ETiOSSubmissionFile.createFileWithContent(fileName: fileName as! String, content: batchContent as! String)
                // after saving batch content successfully, remove from watch
                if WCSession.default.isReachable {
                    WCSession.default.sendMessage([
                        "action": "removeFile",
                        "fileName": fileName as! String,
                    ], replyHandler: wcReplyHandler, errorHandler: wcErrorHandler)
                }
                
                // send to grpc server
                if let submission = ETgRPCSubmission.getInstance() {
                    submission.trigger()
                }
            } catch {
                print("failed to create a submission file \(fileName as! String) from received wc batch content, error=\(error)")
            }
        }
    }
    
    private func wcReplyHandler(message: [String:Any]) {
        print("wcReplyHandler \(message)")
    }
    private func wcErrorHandler(error: Error) {
        print("wcErrorHandler \(error)")
    }
}
