import Foundation
import UIKit


/// ApplicationAdapter: Wraps UIApplication's API. Meant for Unit Testing Purposes.
///
protocol ApplicationAdapter: class {

    /// App's Badge Count
    ///
    var applicationIconBadgeNumber: Int { get set }

    /// App's State
    ///
    var applicationState: UIApplication.State { get }

    /// Registers the app for Push Notifications
    ///
    func registerForRemoteNotifications()

    /// Displays the Details for the specified Notification.
    ///
    func displayNotificationDetails(for noteID: Int)
}


/// UIApplication: ApplicationAdapter Conformance.
///
extension UIApplication: ApplicationAdapter {

    /// Displays the Details for the specified Notification ID
    ///
    func displayNotificationDetails(for noteID: Int) {
        // TODO: Wire the actual NoteID
        MainTabBarController.switchToNotificationsTab()
    }
}
