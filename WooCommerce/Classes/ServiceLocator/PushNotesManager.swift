import Combine
import Foundation
import UIKit
import Yosemite

protocol PushNotesManager {

    /// An observable that emits values when the Remote Notifications are received while the app is
    /// in the foreground.
    ///
    var foregroundNotifications: AnyPublisher<PushNotification, Never> { get }

    /// An observable that emits values when the user taps to view the in-app notification while the app is
    /// in the foreground.
    ///
    var foregroundNotificationsToView: AnyPublisher<PushNotification, Never> { get }

    /// An observable that emits values when a Remote Notification is received while the app is
    /// in inactive.
    ///
    var inactiveNotifications: AnyPublisher<PushNotification, Never> { get }

    /// An observable that emits values when a local notification response is received.
    ///
    var localNotificationResponses: AnyPublisher<UNNotificationResponse, Never> { get }

    /// Resets the Badge Count.
    ///
    func resetBadgeCount(type: Note.Kind)

    /// Resets the Badge Count for all stores.
    ///
    func resetBadgeCountForAllStores(onCompletion: @escaping () -> Void)

    /// Reloads the Badge Count for the site.
    ///
    func reloadBadgeCount()

    /// Registers the Application for Remote Notifications.
    ///
    func registerForRemoteNotifications()

    /// Unregisters the Application from WordPress.com Push Notifications Service.
    ///
    func unregisterForRemoteNotifications()

    /// Requests Authorization to receive Push Notifications, *only* when the current Status is not determined.
    ///
    /// - Parameter includesProvisionalAuth: A boolean that indicates whether to request provisional authorization in order to send trial notifications.
    /// - Parameter onCompletion: Closure to be executed on completion. Receives a Boolean indicating if we've got Push Permission.
    ///
    func ensureAuthorizationIsRequested(includesProvisionalAuth: Bool, onCompletion: ((Bool) -> Void)?)

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

    /// Handles a remote push notification payload when the app is in the background.
    /// - Parameter userInfo: Push notification payload.
    /// - Returns: The result of background sync of notifications.
    func handleRemoteNotificationInTheBackground(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult

    /// Handles user's response to a local or remote notification.
    /// - Parameter response: The user's response to a notification.
    func handleUserResponseToNotification(response: UNNotificationResponse) async

    /// Handles a local or remote notification when the app is in the foreground.
    ///
    /// - Parameter notification: The local or remote notification received in the app.
    /// - Returns: How the notification is displayed in the foreground.
    func handleNotificationInTheForeground(_ notification: UNNotification) async -> UNNotificationPresentationOptions

    /// Requests a local notification to be scheduled under a given trigger.
    /// - Parameters:
    ///   - notification: the notification content.
    ///   - trigger: if nil, the local notification is delivered immediately.
    func requestLocalNotification(_ notification: LocalNotification, trigger: UNNotificationTrigger?)

    /// Cancels a local notification that was previously scheduled.
    /// - Parameter scenarios: the scenarios of the notification to be cancelled.
    func cancelLocalNotification(scenarios: [LocalNotification.Scenario])
}
