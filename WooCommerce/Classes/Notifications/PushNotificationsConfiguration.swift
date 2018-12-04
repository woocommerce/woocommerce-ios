import Foundation
import UIKit
import UserNotifications


/// PushNotificationsConfiguration
///
struct PushNotificationsConfiguration {

    /// Wraps UIApplication's API. Why not use the SDK directly?: Unit Tests!
    ///
    var application: ApplicationWrapper {
        return applicationClosure()
    }

    /// Reference to the UserDefaults Instance that should be used.
    ///
    var defaults: UserDefaults {
        return defaultsClosure()
    }

    /// Reference to the StoresManager that should receive any Yosemite Actions.
    ///
    var storesManager: StoresManager {
        return storesManagerClosure()
    }

    /// Wraps UNUserNotificationCenter API. Why not use the SDK directly?: Unit Tests!
    ///
    var userNotificationCenter: UserNotificationCenterWrapper {
        return userNotificationCenterClosure()
    }

    /// Application Closure: Returns a reference to the ApplicationWrapper
    ///
    private let applicationClosure: () -> ApplicationWrapper

    /// UserDefaults Closure: Returns a reference to UserDefaults
    ///
    private let defaultsClosure: () -> UserDefaults

    /// StoresManager Closure: Returns a reference to StoresManager
    ///
    private let storesManagerClosure: () -> StoresManager

    /// NotificationCenter Closure: Returns a reference to UserNotificationCenterWrapper
    ///
    private let userNotificationCenterClosure: () -> UserNotificationCenterWrapper


    /// Designated Initializer:
    /// Why do we use @autoclosure? because the `UIApplication.shared` property, if executed at the AppDelegate instantiation
    /// point, will cause a circular reference (and hence a crash!).
    ///
    init(application: @autoclosure @escaping () -> ApplicationWrapper,
         defaults: @autoclosure @escaping () -> UserDefaults,
         storesManager: @autoclosure @escaping () -> StoresManager,
         userNotificationCenter: @autoclosure @escaping () -> UserNotificationCenterWrapper) {

        self.applicationClosure = application
        self.defaultsClosure = defaults
        self.storesManagerClosure = storesManager
        self.userNotificationCenterClosure = userNotificationCenter
    }

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
