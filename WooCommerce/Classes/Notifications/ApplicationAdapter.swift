import Foundation
import UIKit


/// ApplicationAdapter: Wraps UIApplication's API. Meant for Unit Testing Purposes.
///
protocol ApplicationAdapter: AnyObject {

    /// App's Badge Count
    ///
    var applicationIconBadgeNumber: Int { get set }

    /// App's State
    ///
    var applicationState: UIApplication.State { get }

    /// Registers the app for Push Notifications
    ///
    func registerForRemoteNotifications()

    /// Presents a given title and optional subtitle and message with an "In App" notification
    ///
    func presentInAppNotification(title: String, subtitle: String?, message: String?, actionTitle: String, actionHandler: @escaping () -> Void)

    /// Presents the Details for the specified Notification.
    ///
    func presentNotificationDetails(for noteID: Int64)
}


/// UIApplication: ApplicationAdapter Conformance.
///
extension UIApplication: ApplicationAdapter {

    /// Presents the Details for the specified Notification ID
    ///
    func presentNotificationDetails(for noteID: Int64) {
        MainTabBarController.presentNotificationDetails(for: noteID)
    }

    /// Presents a given Message with an "In App" notification
    ///
    func presentInAppNotification(title: String, subtitle: String?, message: String?, actionTitle: String, actionHandler: @escaping () -> Void) {
        let notice = Notice(title: title,
                            subtitle: subtitle,
                            message: message,
                            feedbackType: .success,
                            actionTitle: actionTitle,
                            actionHandler: actionHandler)
        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}
