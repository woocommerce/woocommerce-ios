import WatchKit
import UserNotifications
import CocoaLumberjack
import struct NetworkingWatchOS.Note


class AppDelegate: NSObject, ObservableObject, WKApplicationDelegate {

    /// Helper to send tracks events.
    /// This type should be assigned from the main WooApp file.
    ///
    var tracksProvider: WatchTracksProvider?

    /// Stores and modifies app bindings.
    /// This type should be replaced from the main WooApp file.
    ///
    var appBindings: AppBindings = AppBindings()

    /// Setup code after the app finishes launching
    ///
    func applicationDidFinishLaunching() {
        // Set up logging
        setupCocoaLumberjack()

        // Sets the notification delegate
        UNUserNotificationCenter.current().delegate = self
    }

    /// Sets up CocoaLumberjack logging.
    ///
    func setupCocoaLumberjack() {
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = TimeInterval(60*60*24)  // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(DDOSLogger.sharedInstance)
        DDLog.add(fileLogger)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {

        tracksProvider?.sendTracksEvent(.watchPushNotificationTapped)

        // The Watch app only supports order notifications.
        guard let notification = PushNotification.from(userInfo: response.notification.request.content.userInfo),
              notification.kind == Note.Kind.storeOrder else {
            return
        }

        // Trigger order notification app binding
        appBindings.orderNotification = notification
    }
}
