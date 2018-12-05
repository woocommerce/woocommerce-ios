import Foundation
import UIKit
@testable import WooCommerce


/// MockupApplication: UIApplication Mockup!
///
class MockupApplication: ApplicationWrapper {

    /// Badge Count
    ///
    var applicationIconBadgeNumber: Int = .min

    /// Application's State
    ///
    var applicationState: UIApplication.State = .inactive

    /// Indicates if `registerForRemoteNotifications` was called
    ///
    var registerWasCalled = false

    /// Notification Identifiers received via the `displayNotificationDetails` method.
    ///
    var displayDetailsNoteIDs = [Int]()

    /// Inoccuous `registerForRemoteNotifications`
    ///
    func registerForRemoteNotifications() {
        registerWasCalled = true
    }

    /// Inoccuous `displayNotificationDetails`
    ///
    func displayNotificationDetails(for noteID: Int) {
        displayDetailsNoteIDs.append(noteID)
    }

    /// Restores the initial state
    ///
    func reset() {
        registerWasCalled = false
        applicationIconBadgeNumber = .min
        displayDetailsNoteIDs = []
    }
}
