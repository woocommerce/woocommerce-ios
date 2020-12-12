import Foundation
import UIKit
import UserNotifications
import Yosemite

/// PushNotificationsConfiguration
///
struct PushNotificationsConfiguration {

    /// Wraps UIApplication's API. Why not use the SDK directly?: Unit Tests!
    ///
    var application: ApplicationAdapter {
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

    /// Reference to the SupportManager.
    ///
    var supportManager: SupportManagerAdapter {
        return supportManagerClosure()
    }

    /// Wraps UNUserNotificationCenter API. Why not use the SDK directly?: Unit Tests!
    ///
    var userNotificationsCenter: UserNotificationsCenterAdapter {
        return userNotificationsCenterClosure()
    }

    /// Application Closure: Returns a reference to the ApplicationAdapter
    ///
    private let applicationClosure: () -> ApplicationAdapter

    /// UserDefaults Closure: Returns a reference to UserDefaults
    ///
    private let defaultsClosure: () -> UserDefaults

    /// StoresManager Closure: Returns a reference to StoresManager
    ///
    private let storesManagerClosure: () -> StoresManager

    /// SupportManagerAdapter Closure: Returns a reference to the SupportManagerAdapter
    ///
    private let supportManagerClosure: () -> SupportManagerAdapter

    /// NotificationCenter Closure: Returns a reference to UserNotificationsCenterAdapter
    ///
    private let userNotificationsCenterClosure: () -> UserNotificationsCenterAdapter


    /// Designated Initializer:
    /// Why do we use @autoclosure? because the `UIApplication.shared` property, if executed during the AppDelegate instantiation
    /// will cause a circular reference (and hence a crash!).
    ///
    init(application: @autoclosure @escaping () -> ApplicationAdapter,
         defaults: @autoclosure @escaping () -> UserDefaults,
         storesManager: @autoclosure @escaping () -> StoresManager,
         supportManager: @autoclosure @escaping () -> SupportManagerAdapter,
         userNotificationsCenter: @autoclosure @escaping () -> UserNotificationsCenterAdapter) {

        self.applicationClosure = application
        self.defaultsClosure = defaults
        self.storesManagerClosure = storesManager
        self.supportManagerClosure = supportManager
        self.userNotificationsCenterClosure = userNotificationsCenter
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
                                              storesManager: ServiceLocator.stores,
                                              supportManager: ZendeskManager.shared,
                                              userNotificationsCenter: UNUserNotificationCenter.current())
    }
}
