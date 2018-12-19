import Foundation
import UIKit
@testable import WooCommerce


/// MockupApplicationAdapter: UIApplication Mockup!
///
class MockupApplicationAdapter: ApplicationAdapter {

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
    var presentDetailsNoteIDs = [Int]()



    /// Inoccuous `registerForRemoteNotifications`
    ///
    func registerForRemoteNotifications() {
        registerWasCalled = true
    }

    /// Inoccuous `presentInAppNotification`
    ///
    func presentInAppNotification(message: String) {
        presentInAppMessages.append(message)
    }

    /// Inoccuous `displayNotificationDetails`
    ///
    func presentNotificationDetails(for noteID: Int) {
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
