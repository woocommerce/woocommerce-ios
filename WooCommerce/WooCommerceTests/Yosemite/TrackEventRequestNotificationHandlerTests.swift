import XCTest
@testable import WooCommerce
@testable import Networking

/// TrackEventRequestNotificationHandler Unit Tests
///
final class TrackEventRequestNotificationHandlerTests: XCTestCase {

    private var sut: TrackEventRequestNotificationHandler!

    private var mockNotificationCenter: MockNotificationCenter!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        mockNotificationCenter = MockNotificationCenter()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = TrackEventRequestNotificationHandler(notificationCenter: mockNotificationCenter, analytics: analytics)
    }

    override func tearDown() {
        sut = nil
        analytics = nil
        analyticsProvider = nil
        mockNotificationCenter = nil

        super.tearDown()
    }

    func test_create_password_event_is_tracked_upon_receiving_notification() {
        // When
        mockNotificationCenter.post(name: .ApplicationPasswordsNewPasswordCreated, object: nil, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGeneratedSuccessfully(scenario: .regeneration)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("regeneration", actualProperties["scenario"] as? String)
    }

    func test_password_generation_failed_event_is_tracked_upon_authorization_failure() {
        // When
        let error = ApplicationPasswordUseCaseError.unauthorizedRequest
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGenerationFailed(scenario: .regeneration, error: error)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("regeneration", actualProperties["scenario"] as? String)
        assertEqual("authorization_failed", actualProperties["cause"] as? String)
    }

    func test_password_generation_failed_event_is_tracked_when_application_password_disabled() {
        // When
        let error = ApplicationPasswordUseCaseError.applicationPasswordsDisabled
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGenerationFailed(scenario: .regeneration, error: error)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("regeneration", actualProperties["scenario"] as? String)
        assertEqual("feature_disabled", actualProperties["cause"] as? String)
    }

    func test_password_generation_failed_event_is_tracked_upon_custom_login_or_admin_url_error() {
        // When
        let error = ApplicationPasswordUseCaseError.failedToConstructLoginOrAdminURLUsingSiteAddress
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGenerationFailed(scenario: .regeneration, error: error)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("regeneration", actualProperties["scenario"] as? String)
        assertEqual("custom_login_or_admin_url", actualProperties["cause"] as? String)
    }

    func test_password_generation_failed_event_is_tracked_upon_any_error() {
        // When
        let error = MockError.mockError
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGenerationFailed(scenario: .regeneration, error: error)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("regeneration", actualProperties["scenario"] as? String)
        assertEqual("other", actualProperties["cause"] as? String)
    }

    func test_json_parsing_failed_event_is_tracked_with_expected_nil_properties_upon_decoding_error_when_properties_are_not_set() throws {
        // When
        let error = mockDecodingError()
        mockNotificationCenter.post(name: .RemoteDidReceiveJSONParsingError, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.RemoteRequest.jsonParsingError(error, path: nil, entityName: nil)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == expectedEvent.statName.rawValue }))
        let eventProperties = analyticsProvider.receivedProperties[indexOfEvent]
        XCTAssertNil(eventProperties["path"])
        XCTAssertNil(eventProperties["entity"])
        XCTAssertNotNil(eventProperties["debug_decoding_path"])
        XCTAssertNotNil(eventProperties["debug_decoding_description"])
    }

    func test_json_parsing_failed_event_is_tracked_with_properties_upon_decoding_error_when_properties_are_avaiable() throws {
        // When
        let error = mockDecodingError()
        mockNotificationCenter.post(name: .RemoteDidReceiveJSONParsingError, object: error, userInfo: [
            "path": "wc/test",
            "entity": "Product"
        ])

        // Then
        let expectedEvent = WooAnalyticsEvent.RemoteRequest.jsonParsingError(error, path: nil, entityName: nil)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == expectedEvent.statName.rawValue }))
        let eventProperties = analyticsProvider.receivedProperties[indexOfEvent]
        XCTAssertEqual(eventProperties["path"] as? String, "wc/test")
        XCTAssertEqual(eventProperties["entity"] as? String, "Product")
        XCTAssertEqual(eventProperties["debug_decoding_path"] as? String, "")
        XCTAssertEqual(eventProperties["debug_decoding_description"] as? String, "The given data was not valid JSON.")
    }
}

private extension TrackEventRequestNotificationHandlerTests {
    func mockDecodingError() -> Error {
        do {
            _ = try JSONDecoder().decode(String.self, from: Data())
            return MockError.mockError
        } catch {
            return error
        }
    }
}

private class MockNotificationCenter: NotificationCenter { }

private enum MockError: Error { case mockError }
