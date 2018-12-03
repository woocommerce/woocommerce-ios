import Foundation
import UIKit
import UserNotifications


/// PushNotificationsConfiguration
///
struct PushNotificationsConfiguration {

    /// Wraps UIApplication's API. Why not use the SDK directly?: Unit Tests!
    ///
    let application: ApplicationWrapper

    /// Reference to the UserDefaults Instance that should be used.
    ///
    let defaults: UserDefaults

    /// Reference to the StoresManager that should receive any Yosemite Actions.
    ///
    let storesManager: StoresManager

    /// Wraps UNUserNotificationCenter API. Why not use the SDK directly?: Unit Tests!
    ///
    let userNotificationCenter: UserNotificationCenterWrapper
}


// MARK: - PushNotificationsConfiguration Static Methods
//
extension PushNotificationsConfiguration {

    /// Returns the Default PushNotificationsConfiguration
    ///
    static var `default`: PushNotificationsConfiguration {
        return PushNotificationsConfiguration(application: UIApplication.shared,
                                              defaults: .standard,
                                              storesManager: .shared,
                                              userNotificationCenter: UNUserNotificationCenter.current())
    }
}
