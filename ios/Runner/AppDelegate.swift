import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Provide the Google Maps API key. This can be done any time before GMSServices is used.
    GMSServices.provideAPIKey("AIzaSyAKXmd7elGoUcJd9siQGo6PO3duTw1bn9o")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
