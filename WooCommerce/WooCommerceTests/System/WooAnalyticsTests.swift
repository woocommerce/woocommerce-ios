import EventHorizonSDK
import Experiments
import XCTest
@testable import WooCommerce
@testable import Yosemite

/// WooAnalytics Unit Tests
///
class WooAnalyticsTests: XCTestCase {

    /// CredentialsStorage Unit-Testing Instance
    ///
    private var analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider())


    /// CredentialsStorage Unit-Testing Instance
    ///
    private var testingProvider: MockAnalyticsProvider? {
        analytics.analyticsProvider as? MockAnalyticsProvider
    }

    private var stores: MockStoresManager!

    /// Isolated defaults database so tests don't depend on the host's persisted analytics opt-in state.
    ///
    private var userDefaults: UserDefaults!

    /// Suite name backing `userDefaults`, retained so the persistent domain can be cleared in tearDown.
    ///
    private var userDefaultsSuiteName: String!

    private var notificationCenter: NotificationCenter!

    private let sampleSiteID: Int64 = 12345

    private let sampleSiteURL: String = "https://example.com"

    private let originalStores: StoresManager = ServiceLocator.stores

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        let sessionManager = MockSessionManager()
        sessionManager.defaultSite = Site.fake().copy(siteID: sampleSiteID, url: sampleSiteURL)
        stores = MockStoresManager(sessionManager: sessionManager)
        ServiceLocator.setStores(stores)
        userDefaultsSuiteName = UUID().uuidString
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
        notificationCenter = NotificationCenter()
        analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider(), userDefaults: userDefaults, notificationCenter: notificationCenter)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = nil
        userDefaultsSuiteName = nil
        notificationCenter = nil
        super.tearDown()
        ServiceLocator.setStores(originalStores)
    }

    /// Verifies basic events are received by the AnalyticsProvider
    ///
    func testBasicEventsReceived() {
        analytics.track(.applicationOpened)
        XCTAssertEqual(testingProvider?.receivedEvents.count, 1)
        XCTAssertEqual(testingProvider?.receivedProperties.count, 0)
        XCTAssertEqual(testingProvider?.receivedEvents.first, WooAnalyticsStat.applicationOpened.rawValue)

        analytics.track(.applicationClosed)
        XCTAssertEqual(testingProvider?.receivedEvents.count, 2)
        XCTAssertEqual(testingProvider?.receivedProperties.count, 0)
        XCTAssertEqual(testingProvider?.receivedEvents[1], WooAnalyticsStat.applicationClosed.rawValue)
    }

    /// Verifies events with properties are received by the AnalyticsProvider
    ///
    func testEventsWithPropertiesReceived() {
        analytics.track(.applicationOpened, withProperties: Constants.testProperty1)
        XCTAssertEqual(testingProvider?.receivedEvents.count, 1)
        XCTAssertEqual(testingProvider?.receivedProperties.count, 1)
        XCTAssertEqual(testingProvider?.receivedEvents.first, WooAnalyticsStat.applicationOpened.rawValue)
        if let receivedProperty1 = testingProvider?.receivedProperties[0] as? [String: String] {
            XCTAssertEqual(receivedProperty1, Constants.testProperty1)
        } else {
            XCTFail("Expected property not found")
        }

        analytics.track(.applicationClosed, withProperties: Constants.testProperty2)
        XCTAssertEqual(testingProvider?.receivedEvents.count, 2)
        XCTAssertEqual(testingProvider?.receivedProperties.count, 2)
        XCTAssertEqual(testingProvider?.receivedEvents[1], WooAnalyticsStat.applicationClosed.rawValue)
        if let receivedProperty2 = testingProvider?.receivedProperties[1] as? [String: String] {
            XCTAssertEqual(receivedProperty2, Constants.testProperty2)
        } else {
            XCTFail("Expected property not found")
        }
    }
    /// Verifies an event with an error is received by the AnalyticsProvider
    ///
    func testEventsWithErrorReceived() {
        let testError = NSError(domain: Constants.testErrorDomain, code: Constants.testErrorCode, userInfo: Constants.testErrorUserInfo)
        analytics.track(.applicationOpened, withError: testError)
        XCTAssertEqual(testingProvider?.receivedEvents.count, 1)
        XCTAssertEqual(testingProvider?.receivedProperties.count, 1)
        XCTAssertEqual(testingProvider?.receivedEvents.first, WooAnalyticsStat.applicationOpened.rawValue)

        guard let receivedProperty1 = testingProvider?.receivedProperties[0] as? [String: String] else {
            XCTFail("Expected property not found")
            return
        }

        /// Note: iOS 12 is shuffling several dictionaries (especially when it comes to serializing [:] > URL Parameters).
        /// For that reason, we'll proceed with a bit of a more lengthy but robust check.
        ///
        for (key, value) in Constants.testErrorReceivedProperty {
            XCTAssertEqual(value, receivedProperty1[key])
        }

        /// Second note: the error's userInfo, as a string, is getting swizzled. We'll ensure the expected payload is there,
        /// but the exact position isn't guarranteed!
        ///
        let descriptionIncludingUserInfo = receivedProperty1[Constants.testErrorDescriptionKey]
        for (_, descriptionSubstring) in Constants.testErrorUserInfo {
            XCTAssert(descriptionIncludingUserInfo?.contains(descriptionSubstring) == true)
        }
    }

    /// Verifies an event with an error and properties is received by the AnalyticsProvider
    ///
    func test_events_with_properties_and_error_include_combined_properties() {
        // Given
        let testError = NSError(domain: Constants.testErrorDomain, code: Constants.testErrorCode, userInfo: Constants.testErrorUserInfo)

        // When
        analytics.track(.applicationOpened, properties: Constants.testProperty1, error: testError)

        // Then
        XCTAssertEqual(testingProvider?.receivedEvents.count, 1)
        XCTAssertEqual(testingProvider?.receivedProperties.count, 1)
        XCTAssertEqual(testingProvider?.receivedEvents.first, WooAnalyticsStat.applicationOpened.rawValue)

        guard let receivedProperty1 = testingProvider?.receivedProperties[0] as? [String: String] else {
            XCTFail("Expected property not found")
            return
        }

        /// Note: iOS 12 is shuffling several dictionaries (especially when it comes to serializing [:] > URL Parameters).
        /// For that reason, we'll proceed with a bit of a more lengthy but robust check.
        ///
        for (key, value) in Constants.testErrorAndPropertyReceivedProperty {
            XCTAssertEqual(value, receivedProperty1[key])
        }

        /// Second note: the error's userInfo, as a string, is getting swizzled. We'll ensure the expected payload is there,
        /// but the exact position isn't guaranteed!
        ///
        let descriptionIncludingUserInfo = receivedProperty1[Constants.testErrorDescriptionKey]
        for (_, descriptionSubstring) in Constants.testErrorUserInfo {
            XCTAssert(descriptionIncludingUserInfo?.contains(descriptionSubstring) == true)
        }
    }

    /// Test user opted out
    ///
    func testUserOptedOut() {
        testingProvider?.clearUsers()
        XCTAssertTrue(testingProvider?.userID == nil)
        XCTAssertTrue(testingProvider?.userOptedIn == false)
    }

    /// Test clear all events
    ///
    func testClearAllEvents() {
        testingProvider?.clearEvents()
        XCTAssertEqual(testingProvider?.receivedEvents.count, 0)
    }

    @MainActor
    func test_refreshUserData_when_logged_out_then_starts_AB_tests_after_provider_refresh() {
        assertABTestsStartAfterProviderRefresh(credentials: nil, expectedContext: .loggedOut)
    }

    @MainActor
    func test_refreshUserData_when_authenticated_with_WPCom_then_starts_AB_tests_after_provider_refresh() {
        assertABTestsStartAfterProviderRefresh(credentials: SessionSettings.wpcomCredentials, expectedContext: .loggedIn)
    }

    @MainActor
    func test_initialize_when_authenticated_with_site_credentials_then_starts_AB_tests_after_provider_refresh() {
        assertABTestsStartAfterProviderRefresh(credentials: SessionSettings.wporgCredentials,
                                              expectedContext: .loggedIn,
                                              operation: { $0.initialize() })
    }

    @MainActor
    func test_initialize_when_authenticated_with_application_password_then_starts_AB_tests_after_provider_refresh() {
        assertABTestsStartAfterProviderRefresh(credentials: SessionSettings.applicationPasswordCredentials,
                                              expectedContext: .loggedIn,
                                              operation: { $0.initialize() })
    }

    @MainActor
    func test_initialize_when_logged_out_then_starts_AB_tests_after_provider_refresh() {
        assertABTestsStartAfterProviderRefresh(credentials: nil, expectedContext: .loggedOut, operation: { $0.initialize() })
    }

    @MainActor
    func test_initialize_when_authenticated_with_WPCom_then_starts_AB_tests_after_provider_refresh() {
        assertABTestsStartAfterProviderRefresh(credentials: SessionSettings.wpcomCredentials,
                                              expectedContext: .loggedIn,
                                              operation: { $0.initialize() })
    }

    @MainActor
    func test_setUserHasOptedOut_when_enabling_after_site_credential_launch_then_refreshes_provider_before_AB_tests() {
        assertABTestsStartAfterProviderRefresh(credentials: SessionSettings.wporgCredentials,
                                              expectedContext: .loggedIn,
                                              operation: {
            $0.userHasOptedIn = false
            $0.initialize()
            $0.setUserHasOptedOut(false)
        })
    }

    @MainActor
    func test_setUserHasOptedOut_when_enabling_after_application_password_launch_then_refreshes_provider_before_AB_tests() {
        assertABTestsStartAfterProviderRefresh(credentials: SessionSettings.applicationPasswordCredentials,
                                              expectedContext: .loggedIn,
                                              operation: {
            $0.userHasOptedIn = false
            $0.initialize()
            $0.setUserHasOptedOut(false)
        })
    }

    @MainActor
    func test_setUserHasOptedOut_when_already_enabled_after_site_credential_login_then_does_not_refresh_provider_again() {
        assertLoginDoesNotRefreshProvider(credentials: SessionSettings.wporgCredentials, operation: { $0.setUserHasOptedOut(false) })
    }

    @MainActor
    func test_setUserHasOptedOut_when_already_enabled_after_application_password_login_then_does_not_refresh_provider_again() {
        assertLoginDoesNotRefreshProvider(credentials: SessionSettings.applicationPasswordCredentials, operation: { $0.setUserHasOptedOut(false) })
    }

    @MainActor
    func test_refreshUserData_when_signing_in_with_site_credentials_then_does_not_refresh_provider_again() {
        assertLoginDoesNotRefreshProvider(credentials: SessionSettings.wporgCredentials)
    }

    @MainActor
    func test_refreshUserData_when_signing_in_with_application_password_then_does_not_refresh_provider_again() {
        assertLoginDoesNotRefreshProvider(credentials: SessionSettings.applicationPasswordCredentials)
    }

    @MainActor
    private func assertLoginDoesNotRefreshProvider(credentials: Credentials,
                                                  operation: (WooAnalytics) -> Void = { $0.refreshUserData() },
                                                  file: StaticString = #filePath,
                                                  line: UInt = #line) {
        // Given: startup has restored the anonymous identity before the merchant signs in.
        let sessionManager = MockSessionManager()
        stores = MockStoresManager(sessionManager: sessionManager)
        ServiceLocator.setStores(stores)
        let provider = MockAnalyticsProvider()
        provider.defersRefreshUserDataCompletion = true
        var startedContexts: [ExperimentContext] = []
        analytics = WooAnalytics(analyticsProvider: provider,
                                 userDefaults: userDefaults,
                                 notificationCenter: notificationCenter,
                                 startABTest: { context in
            startedContexts.append(context)
        })
        analytics.initialize()
        provider.completeRefreshUserData()
        XCTAssertEqual(provider.refreshUserDataCallCount, 1, file: file, line: line)
        XCTAssertEqual(startedContexts, [.loggedOut], file: file, line: line)

        // When: the login event is recorded immediately before the authentication state changes.
        analytics.track(.applicationPasswordAuthorizationApproved)
        sessionManager.defaultCredentials = credentials
        stores = MockStoresManager(sessionManager: sessionManager)
        ServiceLocator.setStores(stores)
        operation(analytics)

        // Then: preserve the login-time skip from #9485 while starting logged-in experiments.
        XCTAssertEqual(provider.refreshUserDataCallCount, 1, file: file, line: line)
        XCTAssertEqual(startedContexts, [.loggedOut, .loggedIn], file: file, line: line)
    }

    @MainActor
    func test_refreshUserData_when_opted_out_then_does_not_refresh_provider_or_start_AB_tests() {
        // Given
        let provider = MockAnalyticsProvider()
        var startedContexts: [ExperimentContext] = []
        analytics = WooAnalytics(analyticsProvider: provider,
                                 userDefaults: userDefaults,
                                 notificationCenter: notificationCenter,
                                 startABTest: { context in
            startedContexts.append(context)
        })
        analytics.userHasOptedIn = false

        // When
        analytics.refreshUserData()

        // Then
        XCTAssertEqual(provider.refreshUserDataCallCount, 0)
        XCTAssertTrue(startedContexts.isEmpty)
    }

    @MainActor
    func test_initialize_when_opted_out_then_does_not_refresh_provider_or_start_AB_tests() {
        // Given
        let provider = MockAnalyticsProvider()
        var startedContexts: [ExperimentContext] = []
        analytics = WooAnalytics(analyticsProvider: provider,
                                 userDefaults: userDefaults,
                                 notificationCenter: notificationCenter,
                                 startABTest: { context in
            startedContexts.append(context)
        })
        analytics.userHasOptedIn = false

        // When
        analytics.initialize()

        // Then
        XCTAssertEqual(provider.refreshUserDataCallCount, 0)
        XCTAssertTrue(startedContexts.isEmpty)
    }

    @MainActor
    private func assertABTestsStartAfterProviderRefresh(credentials: Credentials?,
                                                      expectedContext: ExperimentContext,
                                                      operation: (WooAnalytics) -> Void = { $0.refreshUserData() },
                                                      file: StaticString = #filePath,
                                                      line: UInt = #line) {
        // Given
        let sessionManager = MockSessionManager()
        sessionManager.defaultCredentials = credentials
        stores = MockStoresManager(sessionManager: sessionManager)
        ServiceLocator.setStores(stores)
        let provider = MockAnalyticsProvider()
        provider.defersRefreshUserDataCompletion = true
        var startedContexts: [ExperimentContext] = []
        analytics = WooAnalytics(analyticsProvider: provider,
                                 userDefaults: userDefaults,
                                 notificationCenter: notificationCenter,
                                 startABTest: { context in
            startedContexts.append(context)
        })

        // When
        operation(analytics)

        // Then: experiments must wait until the test explicitly completes the refresh.
        XCTAssertEqual(provider.refreshUserDataCallCount, 1, file: file, line: line)
        XCTAssertTrue(startedContexts.isEmpty, file: file, line: line)

        // When
        provider.completeRefreshUserData()

        // Then
        XCTAssertEqual(startedContexts, [expectedContext], file: file, line: line)
    }

    func test_events_when_logged_in_include_site_properties() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL,
                                                                    isJetpackThePluginInstalled: true,
                                                                    isJetpackConnected: true),
                                                                   defaultStoreUUID: "sample_store_uuid",
                                                                   cachedWooCommerceVersion: "10.0"))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)

        // When
        analytics.track(.sitePickerContinueTapped, withProperties: Constants.testProperty1)
        XCTAssertEqual(testingProvider.receivedEvents.first, WooAnalyticsStat.sitePickerContinueTapped.rawValue)

        guard let receivedProperties = testingProvider.receivedProperties.first as? [AnyHashable: AnyHashable] else {
            return XCTFail("Non-equatable properties found")
        }

        let expectedProperties: [String: AnyHashable] = [
            "blog_id": sampleSiteID,
            "is_wpcom_store": false,
            "is_jetpack_installed": true,
            "is_jetpack_connected": true,
            "is_jetpack_cp_connected": false,
            "site_url": sampleSiteURL,
            "prop-key1": "prop-value1",
            "store_id": "sample_store_uuid",
            "cached_woo_core_version": "10.0"
        ]

        for property in expectedProperties {
            let receivedPropertyValue = try? XCTUnwrap(receivedProperties[property.key], "Property \(property.key) not found")
            assertEqual(property.value, receivedPropertyValue)
        }
    }

    func test_events_when_logged_out_do_not_include_site_properties() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL)))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)

        // When
        analytics.track(.sitePickerContinueTapped, withProperties: Constants.testProperty1)
        XCTAssertEqual(testingProvider.receivedEvents.first, WooAnalyticsStat.sitePickerContinueTapped.rawValue)

        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }

        let expectedToBeAbsentProperties = [
            "blog_id",
            "is_wpcom_store",
            "is_jetpack_installed",
            "is_jetpack_connected",
            "is_jetpack_cp_connected",
            "site_url",
            "store_id",
            "cached_woo_core_version"
        ]

        for property in expectedToBeAbsentProperties {
            XCTAssertNil(receivedProperties[property])
        }
    }

    // MARK: - Event Bridge

    func test_track_Event_when_authenticated_then_includes_site_properties() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL)))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)

        // When
        analytics.track(Event.bookingDetailAttendanceStatusUpdate(bookingStatus: .attended))

        // Then
        XCTAssertEqual(testingProvider.receivedEvents.first, "booking_detail_attendance_status_update")
        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }
        XCTAssertEqual(receivedProperties["booking_status"] as? String, "attended")
        XCTAssertEqual(receivedProperties["blog_id"] as? Int64, sampleSiteID)
    }

    func test_track_Event_when_not_authenticated_then_skips_site_properties() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)

        // When
        analytics.track(Event.bookingDetailAttendanceStatusUpdate(bookingStatus: .attended))

        // Then
        XCTAssertEqual(testingProvider.receivedEvents.first, "booking_detail_attendance_status_update")
        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }
        XCTAssertEqual(receivedProperties["booking_status"] as? String, "attended")
        XCTAssertNil(receivedProperties["blog_id"])
    }

    // MARK: - Data-layer tracking by raw event name

    func test_track_by_raw_stat_name_when_authenticated_then_includes_site_properties() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL),
                                                                   defaultStoreUUID: "sample_store_uuid",
                                                                   cachedWooCommerceVersion: "10.0"))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)

        // When
        analytics.track(WooAnalyticsStat.cardReaderLocationSuccess.rawValue, properties: Constants.testProperty1, error: nil)

        // Then
        XCTAssertEqual(testingProvider.receivedEvents.first, WooAnalyticsStat.cardReaderLocationSuccess.rawValue)
        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }
        XCTAssertEqual(receivedProperties["store_id"] as? String, "sample_store_uuid")
        XCTAssertEqual(receivedProperties["blog_id"] as? Int64, sampleSiteID)
        XCTAssertEqual(receivedProperties["prop-key1"] as? String, "prop-value1")
    }

    func test_track_by_raw_stat_name_when_stat_opts_out_of_site_properties_then_skips_them() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL),
                                                                   defaultStoreUUID: "sample_store_uuid"))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)

        // When
        analytics.track(WooAnalyticsStat.wooPushTokenRegisterSuccess.rawValue, properties: Constants.testProperty1, error: nil)

        // Then
        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }
        XCTAssertNil(receivedProperties["store_id"])
        XCTAssertNil(receivedProperties["blog_id"])
    }

    func test_track_by_unknown_event_name_then_skips_site_properties() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL),
                                                                   defaultStoreUUID: "sample_store_uuid"))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)

        // When
        analytics.track("an_event_name_that_is_not_a_stat", properties: Constants.testProperty1, error: nil)

        // Then
        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }
        XCTAssertNil(receivedProperties["store_id"])
    }

    func test_track_by_raw_stat_name_when_session_values_are_nil_then_keeps_caller_supplied_store_and_version_properties() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        // Session values are `nil` until the system information sync completes after login / cold start.
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL),
                                                                   defaultStoreUUID: nil,
                                                                   cachedWooCommerceVersion: nil))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)
        let callerProperties: [AnyHashable: Any] = [
            "cached_woo_core_version": "9.8.0",
            "store_id": "caller_store_uuid"
        ]

        // When
        analytics.track(WooAnalyticsStat.pointOfSaleLocalCatalogSyncFailed.rawValue, properties: callerProperties, error: nil)

        // Then
        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }
        XCTAssertEqual(receivedProperties["cached_woo_core_version"] as? String, "9.8.0")
        XCTAssertEqual(receivedProperties["store_id"] as? String, "caller_store_uuid")
        XCTAssertEqual(receivedProperties["blog_id"] as? Int64, sampleSiteID)
    }

    func test_track_by_raw_stat_name_when_session_and_caller_both_have_values_then_session_values_win() {
        // Given
        guard let testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL),
                                                                   defaultStoreUUID: "session_store_uuid",
                                                                   cachedWooCommerceVersion: "10.0"))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider, userDefaults: userDefaults, notificationCenter: notificationCenter)
        let callerProperties: [AnyHashable: Any] = [
            "cached_woo_core_version": "9.8.0",
            "store_id": "caller_store_uuid"
        ]

        // When
        analytics.track(WooAnalyticsStat.pointOfSaleLocalCatalogSyncFailed.rawValue, properties: callerProperties, error: nil)

        // Then
        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }
        XCTAssertEqual(receivedProperties["cached_woo_core_version"] as? String, "10.0")
        XCTAssertEqual(receivedProperties["store_id"] as? String, "session_store_uuid")
        XCTAssertEqual(receivedProperties["blog_id"] as? Int64, sampleSiteID)
    }
}


// MARK: - Testing Constants
//
private extension WooAnalyticsTests {
    enum Constants {
        static let testProperty1                                = ["prop-key1": "prop-value1"]
        static let testProperty2                                = ["prop-key2": "prop-value2"]

        static let testErrorDomain: String                      = "domain"
        static let testErrorCode: Int                           = 999
        static let testErrorDescriptionKey                      = "error_description"
        static let testErrorUserInfo: [String: String]          = ["userinfo-key1": "Here is the value!", "userinfo-key2": "Here is the second value!"]
        static let testErrorReceivedProperty: [String: String]  = ["error_code": "999", "error_domain": "domain"]

        static let testErrorAndPropertyReceivedProperty: [String: String]  = ["error_code": "999", "error_domain": "domain", "prop-key1": "prop-value1"]
    }
}
