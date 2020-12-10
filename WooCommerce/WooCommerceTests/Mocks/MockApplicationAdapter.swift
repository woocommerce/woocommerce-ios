import Foundation
import UIKit
@testable import WooCommerce


/// MockApplicationAdapter: UIApplication Mock!
///
class MockApplicationAdapter: ApplicationAdapter {

    /// Badge Count
    ///
    var applicationIconBadgeNumber: Int = .min

    /// Application's State
    ///
    var applicationState: UIApplication.State = .inactive

    /// Indicates if `registerForRemoteNotifications` was called
    ///
    var registerWasCalled = false

    /// Messages received via the `presentInAppNotification` method.
    ///
    var presentInAppMessages = [String]()

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
    func presentInAppNotification(message: String) {
        presentInAppMessages.append(message)
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
