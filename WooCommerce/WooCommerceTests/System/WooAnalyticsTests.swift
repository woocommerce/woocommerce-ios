import XCTest
@testable import WooCommerce


/// WooAnalytics Unit Tests
///
class WooAnalyticsTests: XCTestCase {

    /// CredentialsStorage Unit-Testing Instance
    ///
    private var analytics = WooAnalytics(analyticsProvider: MockupAnalyticsProvider())


    /// CredentialsStorage Unit-Testing Instance
    ///
    private var testingProvider: MockupAnalyticsProvider?


    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        testingProvider = analytics.analyticsProvider as? MockupAnalyticsProvider
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
            XCTFail()
        }

        analytics.track(.applicationClosed, withProperties: Constants.testProperty2)
        XCTAssertEqual(testingProvider?.receivedEvents.count, 2)
        XCTAssertEqual(testingProvider?.receivedProperties.count, 2)
        XCTAssertEqual(testingProvider?.receivedEvents[1], WooAnalyticsStat.applicationClosed.rawValue)
        if let receivedProperty2 = testingProvider?.receivedProperties[1] as? [String: String] {
            XCTAssertEqual(receivedProperty2, Constants.testProperty2)
        } else {
            XCTFail()
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
            XCTFail()
            return
        }

        /// Note: iOS 12 is shuffling several dictionaries (specially when it comes to serializing [:] > URL Parameters).
        /// For that reason, we'll proceed with a bit of a more lengthy but robust check.
        ///
        for (key, value) in receivedProperty1 {
            XCTAssertEqual(value, Constants.testErrorReceivedProperty[key])
        }
    }
}


// MARK: - Testing Constants
//
private extension WooAnalyticsTests {
    enum Constants {
        static let testProperty1                               = ["prop-key1": "prop-value1"]
        static let testProperty2                               = ["prop-key2": "prop-value2"]

        static let testErrorDomain: String                     = "domain"
        static let testErrorCode: Int                          = 999
        static let testErrorUserInfo: [String: String]        = ["userinfo-key1": "Here is the value!", "userinfo-key2": "Here is the second value!"]
        static let testErrorReceivedProperty: [String: String] = ["error_code": "999", "error_description": "Error Domain=domain Code=999 \"(null)\" UserInfo={userinfo-key1=Here is the value!, userinfo-key2=Here is the second value!}", "error_domain": "domain"]
    }
}
