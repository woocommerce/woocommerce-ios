import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class LocalNotificationSchedulerTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    func test_notification_is_scheduled_when_remote_feature_flag_is_enabled() async throws {
        // Given
        let pushNotesManager = MockPushNotificationsManager()
        let scheduler = LocalNotificationScheduler(pushNotesManager: pushNotesManager, stores: stores)
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, completion):
                // Remote feature flag is enabled.
                completion(true)
            }
        }

        // When
        let notification = try XCTUnwrap(LocalNotification(scenario: .storeCreationComplete))
        await scheduler.schedule(notification: notification, trigger: nil, remoteFeatureFlag: .storeCreationCompleteNotification)

        // Then
        XCTAssertEqual(pushNotesManager.requestedLocalNotifications, [notification])
    }

    func test_notification_is_not_scheduled_when_remote_feature_flag_is_disabled() async throws {
        // Given
        let pushNotesManager = MockPushNotificationsManager()
        let scheduler = LocalNotificationScheduler(pushNotesManager: pushNotesManager, stores: stores)
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, completion):
                // Remote feature flag is disabled.
                completion(false)
            }
        }

        // When
        let notification = try XCTUnwrap(LocalNotification(scenario: .storeCreationComplete))
        await scheduler.schedule(notification: notification, trigger: nil, remoteFeatureFlag: .storeCreationCompleteNotification)

        // Then
        XCTAssertEqual(pushNotesManager.requestedLocalNotifications, [])
    }

    func test_notification_is_scheduled_when_remote_feature_flag_is_not_specified() async throws {
        // Given
        let pushNotesManager = MockPushNotificationsManager()
        let scheduler = LocalNotificationScheduler(pushNotesManager: pushNotesManager, stores: stores)

        // When
        let notification = try XCTUnwrap(LocalNotification(scenario: .storeCreationComplete))
        await scheduler.schedule(notification: notification, trigger: nil, remoteFeatureFlag: nil)

        // Then
        XCTAssertEqual(pushNotesManager.requestedLocalNotifications, [notification])
    }

    func test_requestLocalNotificationIfNeeded_is_triggered_when_shouldSkipIfScheduled_is_true() async throws {
        // Given
        let pushNotesManager = MockPushNotificationsManager()
        let scheduler = LocalNotificationScheduler(pushNotesManager: pushNotesManager, stores: stores)
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, completion):
                // Remote feature flag is enabled.
                completion(true)
            }
        }

        // When
        let notification = try XCTUnwrap(LocalNotification(scenario: .storeCreationComplete))
        await scheduler.schedule(notification: notification,
                                 trigger: nil,
                                 remoteFeatureFlag: .storeCreationCompleteNotification,
                                 shouldSkipIfScheduled: true)

        // Then
        XCTAssertEqual(pushNotesManager.requestedLocalNotifications, [])
        XCTAssertEqual(pushNotesManager.requestedLocalNotificationsIfNeeded, [notification])
    }
}

extension LocalNotification: Equatable {
    public static func == (lhs: LocalNotification, rhs: LocalNotification) -> Bool {
        lhs.title == rhs.title &&
        lhs.body == rhs.body &&
        lhs.scenario == rhs.scenario &&
        lhs.actions?.category == rhs.actions?.category &&
        lhs.actions?.actions == rhs.actions?.actions
    }
}

extension LocalNotification.Scenario: Equatable {
    public static func ==(lhs: LocalNotification.Scenario, rhs: LocalNotification.Scenario) -> Bool {
        switch (lhs, rhs) {
        case (.storeCreationComplete, .storeCreationComplete),
            (.loginSiteAddressError, .loginSiteAddressError),
            (.invalidEmailFromSiteAddressLogin, .invalidEmailFromSiteAddressLogin),
            (.invalidEmailFromWPComLogin, .invalidEmailFromWPComLogin),
            (.invalidPasswordFromSiteAddressWPComLogin, .invalidPasswordFromSiteAddressWPComLogin),
            (.invalidPasswordFromWPComLogin, .invalidPasswordFromWPComLogin):
            return true
        case let (.oneDayAfterStoreCreationNameWithoutFreeTrial(lhsStoreName), .oneDayAfterStoreCreationNameWithoutFreeTrial(rhsStoreName)):
            return lhsStoreName == rhsStoreName
        case let (.oneDayBeforeFreeTrialExpires(lhsSiteID, lhsExpiryDate), .oneDayBeforeFreeTrialExpires(rhsSiteID, rhsExpiryDate)):
            return lhsExpiryDate == rhsExpiryDate && lhsSiteID == rhsSiteID
        case let (.oneDayAfterFreeTrialExpires(lhsSiteID), .oneDayAfterFreeTrialExpires(rhsSiteID)):
            return lhsSiteID == rhsSiteID
        default:
            return false
        }
    }
}
