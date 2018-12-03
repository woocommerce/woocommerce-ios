import Foundation
import UIKit
import UserNotifications


/// PushNotificationsConfiguration
///
struct PushNotificationsConfiguration {

    /// Reference to the UserDefaults Instance that should be used.
    ///
    let defaults: UserDefaults

    /// Wraps UIApplication's API. Why not use the SDK directly?: Unit Tests!
    ///
    let application: ApplicationWrapper

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
        return PushNotificationsConfiguration(defaults: .standard,
                                              application: UIApplication.shared,
                                              userNotificationCenter: UNUserNotificationCenter.current())
    }
}
