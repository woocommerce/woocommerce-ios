import Foundation
import UIKit
@testable import WooCommerce


/// MockApplicationAdapter: UIApplication Mock!
///
final class MockApplicationAdapter: ApplicationAdapter {
    /// Badge Count
    ///
    var applicationIconBadgeNumber: Int = .min

    /// Application's State
    ///
    var applicationState: UIApplication.State = .inactive

    /// Indicates if `registerForRemoteNotifications` was called
    ///
    var registerWasCalled = false

    /// Called when `registerForRemoteNotifications` is invoked.
    ///
    var onRegisterForRemoteNotifications: (() -> Void)?

    /// Title, subtitle, and message tuples received via the `presentInAppNotification` method.
    ///
    var presentInAppMessages = [(title: String, subtitle: String?, message: String?)]()

    /// Action handlers received via the `presentInAppNotification` method.
    ///
    var presentInAppActionHandlers = [() -> Void]()

    /// Notification Identifiers received via the `presentNotificationDetails` method.
    ///
    var presentedNotifications = [WooCommerce.PushNotification]()
    var presentDetailsNoteIDs: [Int64] { presentedNotifications.compactMap(\.noteID) }

    /// Innocuous `registerForRemoteNotifications`
    ///
    func registerForRemoteNotifications() {
        registerWasCalled = true
        onRegisterForRemoteNotifications?()
    }

    /// Innocuous `presentInAppNotification`
    ///
    func presentInAppNotification(title: String, subtitle: String?, message: String?, actionTitle: String, actionHandler: @escaping () -> Void) {
        presentInAppMessages.append((title: title, subtitle: subtitle, message: message))
        presentInAppActionHandlers.append(actionHandler)
    }

    /// Innocuous `displayNotificationDetails`
    ///
    func presentNotificationDetails(notification: WooCommerce.PushNotification) {
        presentedNotifications.append(notification)
    }

    /// Restores the initial state
    ///
    func reset() {
        registerWasCalled = false
        onRegisterForRemoteNotifications = nil
        applicationIconBadgeNumber = .min
        presentedNotifications = []
    }
}
