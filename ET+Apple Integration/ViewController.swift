import UIKit
import WatchConnectivity

class ViewController: UIViewController {
    @IBOutlet var okButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    @IBAction func okClicked() {
        ETiOSTools.requestDataWc()
    }
}

extension ViewController {
    private func wcReplyHandler(message: [String:Any]) {
        print("wcReplyHandler \(message)")
    }
    private func wcErrorHandler(error: Error) {
        print("wcErrorHandler \(error)")
    }
}
