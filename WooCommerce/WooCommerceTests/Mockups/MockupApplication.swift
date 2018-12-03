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

    /// Inoccuous `registerForRemoteNotifications`
    ///
    func registerForRemoteNotifications() {
        registerWasCalled = true
    }
}
