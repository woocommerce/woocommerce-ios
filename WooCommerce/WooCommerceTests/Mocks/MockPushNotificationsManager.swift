import Combine
import Foundation
import UIKit
@testable import WooCommerce
import Yosemite

final class MockPushNotificationsManager: PushNotesManager {

    var foregroundNotifications: AnyPublisher<PushNotification, Never> {
        foregroundNotificationsSubject.eraseToAnyPublisher()
    }

    private let foregroundNotificationsSubject = PassthroughSubject<PushNotification, Never>()

    var foregroundNotificationsToView: AnyPublisher<PushNotification, Never> {
        foregroundNotificationsToViewSubject.eraseToAnyPublisher()
    }

    private let foregroundNotificationsToViewSubject = PassthroughSubject<PushNotification, Never>()

    var inactiveNotifications: AnyPublisher<PushNotification, Never> {
        inactiveNotificationsSubject.eraseToAnyPublisher()
    }

    private let inactiveNotificationsSubject = PassthroughSubject<PushNotification, Never>()

    var backgroundNotifications: AnyPublisher<PushNotification, Never> {
        backgroundNotificationsSubject.eraseToAnyPublisher()
    }

    private let backgroundNotificationsSubject = PassthroughSubject<PushNotification, Never>()

    var localNotificationUserResponses: AnyPublisher<UNNotificationResponse, Never> {
        localNotificationResponsesSubject.eraseToAnyPublisher()
    }

    private let localNotificationResponsesSubject = PassthroughSubject<UNNotificationResponse, Never>()

    private(set) var requestedLocalNotifications: [LocalNotification] = []
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

    func requestLocalNotification(_ notification: LocalNotification, trigger: UNNotificationTrigger?) {
        requestedLocalNotifications.append(notification)
    }

    func requestLocalNotificationIfNeeded(_ notification: LocalNotification, trigger: UNNotificationTrigger?) {
        requestedLocalNotificationsIfNeeded.append(notification)
        if let trigger {
            triggersForRequestedLocalNotificationsIfNeeded.append(trigger)
        }
    }

    func cancelLocalNotification(scenarios: [LocalNotification.Scenario]) {
        canceledLocalNotificationScenarios.append(scenarios)
        requestedLocalNotifications.removeAll()
        requestedLocalNotificationsIfNeeded.removeAll()
        triggersForRequestedLocalNotificationsIfNeeded.removeAll()
    }

    func cancelAllNotifications() {
        requestedLocalNotifications.removeAll()
        requestedLocalNotificationsIfNeeded.removeAll()
        triggersForRequestedLocalNotificationsIfNeeded.removeAll()
    }
}

extension MockPushNotificationsManager {
    /// Send a `PushNotification` that will be emitted by the `foregroundNotifications`
    /// observable.
    ///
    func sendForegroundNotification(_ notification: PushNotification) {
        foregroundNotificationsSubject.send(notification)
    }

    /// Send a `PushNotification` that will be emitted by the `foregroundNotificationsToView`
    /// observable.
    ///
    func sendForegroundNotificationToView(_ notification: PushNotification) {
        foregroundNotificationsToViewSubject.send(notification)
    }

    /// Send a `PushNotification` that will be emitted by the `inactiveNotifications`
    /// observable.
    ///
    func sendInactiveNotification(_ notification: PushNotification) {
        inactiveNotificationsSubject.send(notification)
    }

    /// Send a `UNNotificationResponse` that will be emitted by the `localNotificationResponses`
    /// observable.
    ///
    func sendLocalNotificationResponse(_ response: UNNotificationResponse) {
        localNotificationResponsesSubject.send(response)
    }
}
