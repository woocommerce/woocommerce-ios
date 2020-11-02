import Foundation
import UIKit
import Yosemite

protocol PushNotesManager {

    /// An observable that emits values when the Remote Notifications are received while the app is
    /// in the foreground.
    ///
    var foregroundNotifications: Observable<PushNotification> { get }

    /// An observable that emits values when a Remote Notification is received while the app is
    /// in inactive.
    ///
    var inactiveNotifications: Observable<PushNotification> { get }

    /// Resets the Badge Count.
    ///
    func resetBadgeCount(type: Note.Kind)

    /// Resets the Badge Count for all stores.
    ///
    func resetBadgeCountForAllStores(onCompletion: @escaping () -> Void)

    /// Reloads the Badge Count for the site.
    ///
    func reloadBadgeCount()

    /// Registers the Application for Remote Notifgications.
    ///
    func registerForRemoteNotifications()

    /// Unregisters the Application from WordPress.com Push Notifications Service.
    ///
    func unregisterForRemoteNotifications()

    /// Requests Authorization to receive Push Notifications, *only* when the current Status is not determined.
    ///
    /// - Parameter onCompletion: Closure to be executed on completion. Receives a Boolean indicating if we've got Push Permission.
    ///
    func ensureAuthorizationIsRequested(onCompletion: ((Bool) -> Void)?)

    /// Handles Push Notifications Registration Errors. This method unregisters the current device from the WordPress.com
    /// Push Service.
    ///
    /// - Parameter error: Error received after attempting to register for Push Notifications.
    ///
    func registrationDidFail(with error: Error)

    /// Registers the Device Token agains WordPress.com backend, if there's a default account.
    ///
    /// - Parameters:
    ///     - tokenData: APNS's Token Data
    ///     - defaultStoreID: Default WooCommerce Store ID
    ///
    func registerDeviceToken(with tokenData: Data, defaultStoreID: Int64)

    /// Handles a Remote Push Notifican Payload. On completion the `completionHandler` will be executed.
    ///
    func handleNotification(_ userInfo: [AnyHashable: Any],
                            onBadgeUpdateCompletion: @escaping () -> Void,
                            completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
}
