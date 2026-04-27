import UIKit
import Flutter
import GoogleMaps
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Set up the Flutter Method Channel
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let watchChannel = FlutterMethodChannel(name: "com.example.hapticRunning/watch",
                                              binaryMessenger: controller.binaryMessenger)
    
    watchChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "sendHaptic" {
          if let args = call.arguments as? [String: Any], let command = args["command"] as? String {
              self?.sendCommandToWatch(command: command, result: result)
          } else {
              result(FlutterError(code: "INVALID_ARGS", message: "Command not provided", details: nil))
          }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    // 2. Initialize Watch Connectivity
    setupWatchConnectivity()

    GeneratedPluginRegistrant.register(with: self)

    // Provide the Google Maps API key. This can be done any time before GMSServices is used.
    GMSServices.provideAPIKey("AIzaSyAKXmd7elGoUcJd9siQGo6PO3duTw1bn9o")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupWatchConnectivity() {
      if WCSession.isSupported() {
          let session = WCSession.default
          session.delegate = self
          session.activate()
      }
  }

  // 3. Safely send the command to the watch
  private func sendCommandToWatch(command: String, result: @escaping FlutterResult) {
      // Safety Check 1: Is WatchConnectivity supported on this device?
      guard WCSession.isSupported() else {
          result(FlutterError(code: "UNSUPPORTED", message: "Watch connectivity not supported on this device", details: nil))
          return
      }
      let session = WCSession.default
      // Safety Check 2: Is there a watch actually paired to this iPhone?
      guard session.isPaired else {
          result(FlutterError(code: "NOT_PAIRED", message: "No Apple Watch paired", details: nil))
          return
      }
      // Safety Check 3: Is the companion watch app installed?
      guard session.isWatchAppInstalled else {
          result(FlutterError(code: "NOT_INSTALLED", message: "Watch app is not installed", details: nil))
          return
      }
      // Safety Check 4: Is the watch currently reachable? (Screen is on / app is in foreground)
      if session.isReachable {
          session.sendMessage(["command": command], replyHandler: { _ in
              DispatchQueue.main.async {
                  result("Command sent successfully")
              }
          }) { error in
              DispatchQueue.main.async {
                  result(FlutterError(code: "SEND_ERROR", message: error.localizedDescription, details: nil))
              }
          }
      } else {
          do {
              try session.updateApplicationContext(["command": command])
              result("Command queued for when watch wakes up")
          } catch {
              result(FlutterError(code: "SEND_ERROR", message: "Failed to queue command", details: nil))
          }
      }
  }
}

// 4. Implement WCSessionDelegate to satisfy the protocol
extension AppDelegate: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
