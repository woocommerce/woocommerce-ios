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

    /// Presents the Details for the specified Notification.
    ///
    func presentNotificationDetails(for noteID: Int)
}


/// UIApplication: ApplicationAdapter Conformance.
///
extension UIApplication: ApplicationAdapter {

    /// Presents the Details for the specified Notification ID
    ///
    func presentNotificationDetails(for noteID: Int) {
        MainTabBarController.presentNotificationDetails(for: noteID)
    }
}
