import Combine
import Foundation
import UIKit
@testable import WooCommerce
import Yosemite

final class MockPushNotificationsManager: PushNotesManager {
    func disableInAppNotifications() {

    }

    func enableInAppNotifications() {

    }

    var foregroundNotifications: AnyPublisher<WooCommerce.PushNotification, Never> {
        foregroundNotificationsSubject.eraseToAnyPublisher()
    }

    private let foregroundNotificationsSubject = PassthroughSubject<WooCommerce.PushNotification, Never>()

    var foregroundNotificationsToView: AnyPublisher<WooCommerce.PushNotification, Never> {
        foregroundNotificationsToViewSubject.eraseToAnyPublisher()
    }

    private let foregroundNotificationsToViewSubject = PassthroughSubject<WooCommerce.PushNotification, Never>()

    var inactiveNotifications: AnyPublisher<WooCommerce.PushNotification, Never> {
        inactiveNotificationsSubject.eraseToAnyPublisher()
    }

    private let inactiveNotificationsSubject = PassthroughSubject<WooCommerce.PushNotification, Never>()

    var backgroundNotifications: AnyPublisher<WooCommerce.PushNotification, Never> {
        backgroundNotificationsSubject.eraseToAnyPublisher()
    }

    private let backgroundNotificationsSubject = PassthroughSubject<WooCommerce.PushNotification, Never>()

    var localNotificationUserResponses: AnyPublisher<UNNotificationResponse, Never> {
        localNotificationResponsesSubject.eraseToAnyPublisher()
    }

    private let localNotificationResponsesSubject = PassthroughSubject<UNNotificationResponse, Never>()

    private(set) var requestedLocalNotifications: [LocalNotification] = []
    private(set) var triggersForRequestedLocalNotifications: [UNNotificationTrigger] = []
    private(set) var requestedLocalNotificationsIfNeeded: [LocalNotification] = []
    private(set) var triggersForRequestedLocalNotificationsIfNeeded: [UNNotificationTrigger] = []
    private(set) var canceledLocalNotificationScenarios: [[LocalNotification.Scenario]] = []

    func resetBadgeCount(type: Note.Kind) {

    }

    func resetBadgeCountForAllStores(onCompletion: @escaping () -> Void) {

    }

    func reloadBadgeCount() {

    }

    func registerForRemoteNotifications() {

    }

    func unregisterForRemoteNotifications() {

    }

    func ensureAuthorizationIsRequested(includesProvisionalAuth: Bool, onCompletion: ((Bool) -> ())?) {

    }

    func registrationDidFail(with error: Error) {

    }

    func registerDeviceToken(with tokenData: Data, defaultStoreID: Int64) {

    }

    func handleRemoteNotificationInTheBackground(userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        .noData
    }

    func handleUserResponseToNotification(_ response: UNNotificationResponse) async {

    }

    func handleNotificationInTheForeground(_ notification: UNNotification) async -> UNNotificationPresentationOptions {
        .init(rawValue: 0)
    }

    func requestLocalNotification(_ notification: LocalNotification, trigger: UNNotificationTrigger?) async {
        await MainActor.run {
            requestedLocalNotifications.append(notification)
            if let trigger {
                triggersForRequestedLocalNotifications.append(trigger)
            }
        }
    }

    func requestLocalNotificationIfNeeded(_ notification: LocalNotification, trigger: UNNotificationTrigger?) async {
        await MainActor.run {
            requestedLocalNotificationsIfNeeded.append(notification)
            if let trigger {
                triggersForRequestedLocalNotificationsIfNeeded.append(trigger)
            }
        }
    }

    func cancelLocalNotification(scenarios: [LocalNotification.Scenario]) async {
        await MainActor.run {
            canceledLocalNotificationScenarios.append(scenarios)
            requestedLocalNotifications.removeAll()
            requestedLocalNotificationsIfNeeded.removeAll()
            triggersForRequestedLocalNotifications.removeAll()
            triggersForRequestedLocalNotificationsIfNeeded.removeAll()
        }
    }

    func cancelAllNotifications() async {
        await MainActor.run {
            requestedLocalNotifications.removeAll()
            requestedLocalNotificationsIfNeeded.removeAll()
            triggersForRequestedLocalNotifications.removeAll()
            triggersForRequestedLocalNotificationsIfNeeded.removeAll()
        }
    }
}

extension MockPushNotificationsManager {
    /// Send a `PushNotification` that will be emitted by the `foregroundNotifications`
    /// observable.
    ///
    func sendForegroundNotification(_ notification: WooCommerce.PushNotification) {
        foregroundNotificationsSubject.send(notification)
    }

    /// Send a `PushNotification` that will be emitted by the `foregroundNotificationsToView`
    /// observable.
    ///
    func sendForegroundNotificationToView(_ notification: WooCommerce.PushNotification) {
        foregroundNotificationsToViewSubject.send(notification)
    }

    /// Send a `PushNotification` that will be emitted by the `inactiveNotifications`
    /// observable.
    ///
    func sendInactiveNotification(_ notification: WooCommerce.PushNotification) {
        inactiveNotificationsSubject.send(notification)
    }

    /// Send a `UNNotificationResponse` that will be emitted by the `localNotificationResponses`
    /// observable.
    ///
    func sendLocalNotificationResponse(_ response: UNNotificationResponse) {
        localNotificationResponsesSubject.send(response)
    }
}
