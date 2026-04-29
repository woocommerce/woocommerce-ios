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

    private let mockedDeviceID: String?
    let wooPushNotificationToken: String?
    private(set) var siteIDsRegisteredForWooPNs: [Int64]
    let hasStoredSiteIDsRegisteredForWooPNs: Bool
    private(set) var unmarkedSiteIDs: [Int64] = []
    var siteIDsRegisteredForWooPNsPublisher: AnyPublisher<[Int64], Never> {
        siteIDsRegisteredForWooPNsSubject.eraseToAnyPublisher()
    }

    var deviceID: String? {
        mockedDeviceID
    }

    private let siteIDsRegisteredForWooPNsSubject: CurrentValueSubject<[Int64], Never>
    private let localNotificationResponsesSubject = PassthroughSubject<UNNotificationResponse, Never>()

    private(set) var requestedLocalNotifications: [LocalNotification] = []
    private(set) var triggersForRequestedLocalNotifications: [UNNotificationTrigger] = []
    private(set) var requestedLocalNotificationsIfNeeded: [LocalNotification] = []
    private(set) var triggersForRequestedLocalNotificationsIfNeeded: [UNNotificationTrigger] = []
    private(set) var canceledLocalNotificationScenarios: [[LocalNotification.Scenario]] = []
    private(set) var resetBadgeCountKinds: [Note.Kind] = []
    private(set) var registerForRemoteNotificationsCallCount = 0
    private(set) var ensureAuthorizationCallCount = 0
    private(set) var lastIncludesProvisionalAuth: Bool?
    private var authorizationCompletion: ((Bool) -> Void)?
    var onRequestLocalNotificationCalled: (() -> Void)?
    var registerDeviceAndWaitForTokenAcceptanceResult: Result<Int64, Error> = .success(1)
    var registerSiteForSelfDrivenPushNotificationsResult: Result<Void, Error> = .success(())
    private(set) var registeredSiteIDsForSelfDrivenPushNotifications: [Int64] = []

    init(mockedDeviceID: String? = nil,
         wooPushNotificationToken: String? = nil,
         siteIDsRegisteredForWooPNs: [Int64] = [],
         hasStoredSiteIDsRegisteredForWooPNs: Bool? = nil) {
        self.mockedDeviceID = mockedDeviceID
        self.wooPushNotificationToken = wooPushNotificationToken
        self.siteIDsRegisteredForWooPNs = siteIDsRegisteredForWooPNs
        self.hasStoredSiteIDsRegisteredForWooPNs = hasStoredSiteIDsRegisteredForWooPNs ?? !siteIDsRegisteredForWooPNs.isEmpty
        self.siteIDsRegisteredForWooPNsSubject = CurrentValueSubject(siteIDsRegisteredForWooPNs)
    }

    func unmarkSiteAsRegisteredForWooPNs(_ siteID: Int64) {
        unmarkedSiteIDs.append(siteID)
        siteIDsRegisteredForWooPNs.removeAll { $0 == siteID }
    }

    func resetBadgeCount(type: Note.Kind) {
        resetBadgeCountKinds.append(type)
    }

    func resetBadgeCountForAllStores(onCompletion: @escaping () -> Void) {

    }

    func reloadBadgeCount() {

    }

    @MainActor
    func registerDeviceAndWaitForTokenAcceptance() async throws -> Int64 {
        // Yield to allow MainActor scheduling to settle
        await Task.yield()
        return try registerDeviceAndWaitForTokenAcceptanceResult.get()
    }

    @MainActor
    func registerSiteForSelfDrivenPushNotifications(_ siteID: Int64) async throws {
        registeredSiteIDsForSelfDrivenPushNotifications.append(siteID)
        try registerSiteForSelfDrivenPushNotificationsResult.get()
        if !siteIDsRegisteredForWooPNs.contains(siteID) {
            siteIDsRegisteredForWooPNs.append(siteID)
        }
    }

    func registerForRemoteNotifications() {
        registerForRemoteNotificationsCallCount += 1
    }

    func unregisterForRemoteNotifications(onCompletion: @escaping () -> Void) {

    }

    func ensureAuthorizationIsRequested(includesProvisionalAuth: Bool, onCompletion: ((Bool) -> ())?) {
        ensureAuthorizationCallCount += 1
        lastIncludesProvisionalAuth = includesProvisionalAuth
        authorizationCompletion = onCompletion
    }

    func registrationDidFail(with error: Error) {

    }

    func registerDeviceToken(with tokenData: Data) {

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
            onRequestLocalNotificationCalled?()
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
    func completeAuthorizationRequest(isAllowed: Bool) {
        authorizationCompletion?(isAllowed)
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
