import Foundation
import WatchConnectivity
import Combine
import WatchKit

class WatchViewModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var latestCommand: String = "Waiting..."
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // Triggered when the iPhone uses sendMessage() and expects a reply
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            if let command = message["command"] as? String {
                self.latestCommand = command
                // Execute watch-side logic here
                self.triggerHaptic(for: command)
                
                replyHandler(["status": "success"])
            }
        }
    }
    
    // Triggered when the iPhone uses updateApplicationContext()
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if let command = applicationContext["command"] as? String {
                self.latestCommand = command
                self.triggerHaptic(for: command)
            }
        }
    }
    
    private func triggerHaptic(for command: String) {
        let hapticType: WKHapticType
        
        switch command {
        case "notification":
            hapticType = .notification
        case "directionUp":
            hapticType = .directionUp
        case "directionDown":
            hapticType = .directionDown
        case "success":
            hapticType = .success
        case "failure":
            hapticType = .failure
        case "retry":
            hapticType = .retry
        case "start":
            hapticType = .start
        case "stop":
            hapticType = .stop
        case "click":
            hapticType = .click
        case "navigationGenericManeuver":
            hapticType = .navigationGenericManeuver
        case "navigationLeftTurn":
            hapticType = .navigationLeftTurn
        case "navigationRightTurn":
            hapticType = .navigationRightTurn
        default:
            hapticType = .notification
        }
        
        WKInterfaceDevice.current().play(hapticType)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
