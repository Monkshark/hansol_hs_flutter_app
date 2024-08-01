import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let channelName = "com.example.hansol_high_school/alarm"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.binaryMessenger)

        channel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "scheduleMealNotification" {
                guard let args = call.arguments as? [String: Any],
                      let hour = args["hour"] as? Int,
                      let minute = args["minute"] as? Int,
                      let mealType = args["mealType"] as? String,
                      let mealMenu = args["mealMenu"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument", details: nil))
                    return
                }
                self?.scheduleMealNotification(hour: hour, minute: minute, mealType: mealType, mealMenu: mealMenu)
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        requestNotificationAuthorization()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Request authorization failed: \(error)")
            }
        }
    }

    private func scheduleMealNotification(hour: Int, minute: Int, mealType: String, mealMenu: String) {
        let content = UNMutableNotificationContent()
        content.title = mealType
        content.body = "아래로 당겨서 메뉴 확인"
        content.sound = UNNotificationSound.default
        content.userInfo = ["mealMenu": mealMenu]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            } else {
                print("Scheduled \(mealType) notification for \(hour):\(minute) with menu: \(mealMenu)")
            }
        }
    }
}
