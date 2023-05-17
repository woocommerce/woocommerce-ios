import XCTest
@testable import WooCommerce
@testable import Yosemite

final class StorePlanSynchronizerTests: XCTestCase {

    // Mocked stores manager
    var stores = MockStoresManager(sessionManager: .testingInstance)

    // Mocked session
    var session = SessionManager.makeForTesting()

    // Site ID
    let sampleSiteID: Int64 = 123

    override func setUp() {
        session = SessionManager.makeForTesting(authenticated: true, isWPCom: true)
        session.defaultSite = .fake().copy(siteID: sampleSiteID, isWordPressComStore: true)
        stores = MockStoresManager(sessionManager: session)

        super.setUp()
    }

    func test_synchronizer_has_not_loaded_state_if_there_is_not_a_site() {
        // Given
        session.defaultSite = nil

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)

        // Then
        XCTAssertEqual(synchronizer.planState, .notLoaded)
    }

    func test_synchronizer_has_unavailable_state_on_a_non_wpcom_site() {
        // Given
        session.defaultSite = .fake().copy(siteID: sampleSiteID)

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)

        // Then
        XCTAssertEqual(synchronizer.planState, .unavailable)
    }

    func test_synchronizer_fetches_plan_immediately_if_there_is_a_wpcom_site() {
        // Given
        let samplePlan = WPComSitePlan(hasDomainCredit: false)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(samplePlan))
            default:
                break
            }
        }

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)

        // Then
        XCTAssertEqual(synchronizer.planState, .loaded(samplePlan))
    }

    func test_synchronizer_reflects_error_state() {
        // Given
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
            default:
                break
            }
        }

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores)

        // Then
        XCTAssertEqual(synchronizer.planState, .failed)
    }

    func test_local_notifications_are_scheduled_if_the_site_has_trial_plan_with_expiry_date_at_least_2_days_away() throws {
        // Given
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let pushNotesManager = MockPushNotificationsManager()
        let expiryDate = Date().normalizedDate().addingTimeInterval(86400 * 5) // 5 days from now
        let trialPlan = WPComSitePlan(id: "1052", hasDomainCredit: false, expiryDate: expiryDate)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(trialPlan))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, completion):
                // Remote feature flag is enabled.
                completion(true)
            }
        }

        // When
        _ = StorePlanSynchronizer(stores: stores, timeZone: timeZone, pushNotesManager: pushNotesManager)

        // Then
        waitUntil(timeout: 3) {
            pushNotesManager.requestedLocalNotificationsIfNeeded.count == 2
        }
        let ids = pushNotesManager.requestedLocalNotificationsIfNeeded.map(\.scenario.identifier)
        let expectedIDs = [
            LocalNotification.Scenario.IdentifierPrefix.oneDayBeforeFreeTrialExpires + "\(sampleSiteID)",
            LocalNotification.Scenario.IdentifierPrefix.oneDayAfterFreeTrialExpires + "\(sampleSiteID)",
        ]
        assertEqual(expectedIDs, ids)

        let triggers = pushNotesManager.triggersForRequestedLocalNotificationsIfNeeded
        let beforeExpirationTrigger = try XCTUnwrap(triggers.first as? UNCalendarNotificationTrigger)
        let beforeExpirationTriggerDate = try XCTUnwrap(Calendar.current.date(from: beforeExpirationTrigger.dateComponents))
        assertEqual(86400, expiryDate.timeIntervalSince(beforeExpirationTriggerDate)) // 1 day

        let afterExpirationTrigger = try XCTUnwrap(triggers.last as? UNCalendarNotificationTrigger)
        let afterExpirationTriggerDate = try XCTUnwrap(Calendar.current.date(from: afterExpirationTrigger.dateComponents))
        assertEqual(86400, afterExpirationTriggerDate.timeIntervalSince(expiryDate)) // 1 day
    }

    func test_expired_trial_plan_local_notification_is_scheduled_if_the_site_has_trial_plan_being_expired_for_at_most_1_day() throws {
        // Given
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let pushNotesManager = MockPushNotificationsManager()
        let expiryDate = Date().normalizedDate().addingTimeInterval(-86400/2) // expired for half a day
        let trialPlan = WPComSitePlan(id: "1052", hasDomainCredit: false, expiryDate: expiryDate)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(trialPlan))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, completion):
                // Remote feature flag is enabled.
                completion(true)
            }
        }

        // When
        _ = StorePlanSynchronizer(stores: stores, timeZone: timeZone, pushNotesManager: pushNotesManager)

        // Then
        waitUntil(timeout: 3) {
            pushNotesManager.requestedLocalNotificationsIfNeeded.count == 1
        }
        let ids = pushNotesManager.requestedLocalNotificationsIfNeeded.map(\.scenario.identifier)
        let expectedIDs = [
            LocalNotification.Scenario.IdentifierPrefix.oneDayAfterFreeTrialExpires + "\(sampleSiteID)",
        ]
        assertEqual(expectedIDs, ids)
    }

    func test_local_notifications_are_canceled_after_the_site_is_upgraded() throws {
        // Given
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let pushNotesManager = MockPushNotificationsManager()
        let expiryDate = Date().normalizedDate().addingTimeInterval(86400 * 5) // 5 days from now
        var expectedPlan = WPComSitePlan(id: "1052", hasDomainCredit: false, expiryDate: expiryDate)
        stores.whenReceivingAction(ofType: PaymentAction.self) { action in
            switch action {
            case .loadSiteCurrentPlan(_, let completion):
                completion(.success(expectedPlan))
            default:
                break
            }
        }
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(_, _, completion):
                // Remote feature flag is enabled.
                completion(true)
            }
        }

        // When
        let synchronizer = StorePlanSynchronizer(stores: stores, timeZone: timeZone, pushNotesManager: pushNotesManager)

        // Then
        waitUntil(timeout: 3) {
            pushNotesManager.requestedLocalNotificationsIfNeeded.count == 2
        }

        // When
        expectedPlan = WPComSitePlan(hasDomainCredit: false)
        synchronizer.reloadPlan()

        // Then
        waitUntil(timeout: 3) {
            pushNotesManager.requestedLocalNotificationsIfNeeded.isEmpty && pushNotesManager.canceledLocalNotificationScenarios.count == 2
        }
    }
}
