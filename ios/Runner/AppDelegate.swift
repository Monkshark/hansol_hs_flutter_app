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
                      let hour = args["hour"] as? String,
                      let minute = args["minute"] as? String,
                      let notificationTitle = args["notificationTitle"] as? String,
                      let mealMenu = args["mealMenu"] as? String,
                      let hourInt = Int(hour),
                      let minuteInt = Int(minute) else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument", details: nil))
                    return
                }
                self?.scheduleMealNotification(hour: hourInt, minute: minuteInt, notificationTitle: notificationTitle, mealMenu: mealMenu)
                result(nil)
            } else if call.method == "cancelMealNotification" {
                guard let args = call.arguments as? [String: Any],
                      let notificationTitle = args["notificationTitle"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid argument", details: nil))
                    return
                }
                self?.cancelMealNotification(notificationTitle: notificationTitle)
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

    private func scheduleMealNotification(hour: Int, minute: Int, notificationTitle: String, mealMenu: String) {
        let content = UNMutableNotificationContent()
        content.title = notificationTitle
        content.body = "아래로 당겨서 메뉴 확인"
        content.sound = UNNotificationSound.default
        content.userInfo = ["mealMenu": mealMenu]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let identifier = notificationTitle
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let center = UNUserNotificationCenter.current()
        center.add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            } else {
                print("Scheduled \(notificationTitle) notification for \(hour):\(minute) with menu: \(mealMenu)")
            }
        }
    }

    private func cancelMealNotification(notificationTitle: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationTitle])
        print("Cancelled notification: \(notificationTitle)")
    }
}
