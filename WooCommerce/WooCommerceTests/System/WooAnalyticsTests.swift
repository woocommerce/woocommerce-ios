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

    private let sampleSiteID: Int64 = 12345

    private let sampleSiteURL: String = "https://example.com"

    private let originalStores: StoresManager = ServiceLocator.stores

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL)))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider())
    }

    override func tearDown() {
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

    func test_events_when_logged_in_include_site_properties() {
        // Given
        guard let testingProvider = testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL),
                                                                   defaultStoreUUID: "sample_store_uuid"))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider)

        // When
        analytics.track(.sitePickerContinueTapped, withProperties: Constants.testProperty1)
        XCTAssertEqual(testingProvider.receivedEvents.first, WooAnalyticsStat.sitePickerContinueTapped.rawValue)

        guard let receivedProperties = testingProvider.receivedProperties.first as? [AnyHashable: AnyHashable] else {
            return XCTFail("Non-equatable properties found")
        }

        let expectedProperties: [String: AnyHashable] = [
            "blog_id": sampleSiteID,
            "is_wpcom_store": false,
            "was_ecommerce_trial": false,
            "plan": "",
            "site_url": sampleSiteURL,
            "prop-key1": "prop-value1",
            "store_id": "sample_store_uuid"
        ]

        for property in expectedProperties {
            let receivedPropertyValue = try? XCTUnwrap(receivedProperties[property.key], "Property \(property.key) not found")
            assertEqual(property.value, receivedPropertyValue)
        }
    }

    func test_events_when_logged_out_do_not_include_site_properties() {
        // Given
        guard let testingProvider = testingProvider else {
            return XCTFail("Testing provider not available")
        }
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: false,
                                                                   defaultSite: Site.fake().copy(
                                                                    siteID: sampleSiteID,
                                                                    url: sampleSiteURL)))
        ServiceLocator.setStores(stores)
        analytics = WooAnalytics(analyticsProvider: testingProvider)

        // When
        analytics.track(.sitePickerContinueTapped, withProperties: Constants.testProperty1)
        XCTAssertEqual(testingProvider.receivedEvents.first, WooAnalyticsStat.sitePickerContinueTapped.rawValue)

        guard let receivedProperties = testingProvider.receivedProperties.first else {
            return XCTFail("No properties found")
        }

        let expectedToBeAbsentProperties = [
            "blog_id",
            "is_wpcom_store",
            "was_ecommerce_trial",
            "plan",
            "site_url",
            "store_id"
        ]

        for property in expectedToBeAbsentProperties {
            XCTAssertNil(receivedProperties[property])
        }
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
