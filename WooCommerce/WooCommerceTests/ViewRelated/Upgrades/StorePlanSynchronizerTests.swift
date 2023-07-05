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

    // MARK: twentyFourHoursAfterFreeTrialSubscribed

    func test_twentyFourHoursAfterFreeTrialSubscribed_local_notification_is_scheduled_if_free_trial_subscribed_less_than_24_hrs_ago() throws {
        // Given
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let pushNotesManager = MockPushNotificationsManager()
        let subscribedDate = Date().addingTimeInterval(-Double.random(in: 0..<86400)) // Subscribed within 24 hrs ago
        let trialPlan = WPComSitePlan(id: "1052",
                                      hasDomainCredit: false,
                                      expiryDate: subscribedDate.addingDays(28),
                                      subscribedDate: subscribedDate)
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
        _ = StorePlanSynchronizer(stores: stores,
                                  timeZone: timeZone,
                                  pushNotesManager: pushNotesManager)

        // Then
        waitUntil(timeout: 3) {
            pushNotesManager.requestedLocalNotificationsIfNeeded.isNotEmpty
        }
        let ids = pushNotesManager.requestedLocalNotificationsIfNeeded.map(\.scenario.identifier)
        let expectedID = LocalNotification.Scenario.Identifier.Prefix.twentyFourHoursAfterFreeTrialSubscribed + "\(sampleSiteID)"
        XCTAssertTrue(ids.contains(expectedID))
    }

    func test_twentyFourHoursAfterFreeTrialSubscribed_local_notification_is_not_scheduled_if_free_trial_subscribed_more_than_24_hrs_ago() throws {
        // Given
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let pushNotesManager = MockPushNotificationsManager()
        let subscribedDate = Date().addingTimeInterval(-86401) // Subscribed more than 24 hrs ago
        let trialPlan = WPComSitePlan(id: "1052",
                                      hasDomainCredit: false,
                                      expiryDate: subscribedDate.addingDays(28),
                                      subscribedDate: subscribedDate)
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
        _ = StorePlanSynchronizer(stores: stores,
                                  timeZone: timeZone,
                                  pushNotesManager: pushNotesManager)

        // Then
        let ids = pushNotesManager.requestedLocalNotificationsIfNeeded.map(\.scenario.identifier)
        let expectedID = LocalNotification.Scenario.Identifier.Prefix.twentyFourHoursAfterFreeTrialSubscribed + "\(sampleSiteID)"
        XCTAssertFalse(ids.contains(expectedID))
    }

    // MARK: Cancel local notifications

    func test_local_notifications_are_canceled_after_the_site_is_upgraded() throws {
        // Given
        let timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let pushNotesManager = MockPushNotificationsManager()
        let subscribedDate = Date().addingTimeInterval(-86400/2) // expired for half a day
        var expectedPlan = WPComSitePlan(id: "1052",
                                      hasDomainCredit: false,
                                      expiryDate: subscribedDate.addingDays(28),
                                      subscribedDate: subscribedDate)
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
        let synchronizer = StorePlanSynchronizer(stores: stores,
                                                 timeZone: timeZone,
                                                 pushNotesManager: pushNotesManager)

        // Then
        waitUntil(timeout: 3) {
            pushNotesManager.requestedLocalNotificationsIfNeeded.count == 1
        }

        // When
        expectedPlan = WPComSitePlan(hasDomainCredit: false)
        synchronizer.reloadPlan()

        // Then
        waitUntil(timeout: 3) {
           pushNotesManager.canceledLocalNotificationScenarios.count == 3
        }

        // No local notifications scheduling requested for a non free trial plan
        XCTAssertTrue(pushNotesManager.requestedLocalNotificationsIfNeeded.isEmpty)
    }
}
