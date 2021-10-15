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

    /// Title, subtitle, and message tuples received via the `presentInAppNotification` method.
    ///
    var presentInAppMessages = [(title: String, subtitle: String?, message: String?)]()

    /// Notification Identifiers received via the `presentNotificationDetails` method.
    ///
    var presentDetailsNoteIDs = [Int64]()



    /// Innocuous `registerForRemoteNotifications`
    ///
    func registerForRemoteNotifications() {
        registerWasCalled = true
    }

    /// Innocuous `presentInAppNotification`
    ///
    func presentInAppNotification(title: String, subtitle: String?, message: String?) {
        presentInAppMessages.append((title: title, subtitle: subtitle, message: message))
    }

    /// Innocuous `displayNotificationDetails`
    ///
    func presentNotificationDetails(for noteID: Int64) {
        presentDetailsNoteIDs.append(noteID)
    }

    /// Restores the initial state
    ///
    func reset() {
        registerWasCalled = false
        applicationIconBadgeNumber = .min
        presentDetailsNoteIDs = []
    }
}
