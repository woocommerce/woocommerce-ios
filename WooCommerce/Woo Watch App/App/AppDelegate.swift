import WatchKit
import UserNotifications


class AppDelegate: NSObject, ObservableObject, WKApplicationDelegate {

    /// Stores and modifies app bindings.
    /// This type should be replaced from the main WatchApp file.
    ///
    var appBindings: AppBindings = AppBindings()

    /// Setup code after the app finishes launching
    ///
    func applicationDidFinishLaunching() {
        // Sets the notification delegate
        UNUserNotificationCenter.current().delegate = self
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("receive notification response")
        if response.notification.request.content.categoryIdentifier == "store_order" {
            appBindings.presentNote = true
        }
    }
}
