import XCTest
@testable import WooCommerce
@testable import Networking
import enum Yosemite.ApplicationPasswordGenerationUserInfoKey
import UIKit

/// TrackEventRequestNotificationHandler Unit Tests
///
final class TrackEventRequestNotificationHandlerTests: XCTestCase {

    private var sut: TrackEventRequestNotificationHandler!

    private var mockNotificationCenter: MockNotificationCenter!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!
    private var applicationStateProvider: MockApplicationStateProvider!

    override func setUp() {
        super.setUp()

        mockNotificationCenter = MockNotificationCenter()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        applicationStateProvider = MockApplicationStateProvider()
        let stateProvider = applicationStateProvider!
        sut = TrackEventRequestNotificationHandler(notificationCenter: mockNotificationCenter,
                                                    analytics: analytics,
                                                    applicationStateProvider: { [weak stateProvider] in stateProvider?.state ?? .active })
    }

    override func tearDown() {
        sut = nil
        analytics = nil
        analyticsProvider = nil
        applicationStateProvider = nil
        mockNotificationCenter = nil

        super.tearDown()
    }

    func test_create_password_event_is_tracked_upon_receiving_notification() {
        // When
        mockNotificationCenter.post(name: .ApplicationPasswordsNewPasswordCreated,
                                    object: nil,
                                    userInfo: [ApplicationPasswordGenerationUserInfoKey.isRegeneration: true])

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGeneratedSuccessfully(scenario: .regeneration)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("regeneration", actualProperties["scenario"] as? String)
    }

    @MainActor
    func test_password_generation_failed_event_is_tracked_upon_authorization_failure() {
        // When
        let error = ApplicationPasswordUseCaseError.unauthorizedRequest
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGenerationFailed(scenario: .generation, error: error)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("generation", actualProperties["scenario"] as? String)
        assertEqual("authorization_failed", actualProperties["cause"] as? String)
        XCTAssertNil(actualProperties["path"])
    }

    @MainActor
    func test_password_generation_failed_event_is_tracked_when_application_password_disabled() {
        // When
        let error = ApplicationPasswordUseCaseError.applicationPasswordsDisabled
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGenerationFailed(scenario: .generation, error: error)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("generation", actualProperties["scenario"] as? String)
        assertEqual("feature_disabled", actualProperties["cause"] as? String)
    }

    @MainActor
    func test_password_generation_failed_event_is_tracked_upon_custom_login_or_admin_url_error() {
        // When
        let error = ApplicationPasswordUseCaseError.failedToConstructLoginOrAdminURLUsingSiteAddress
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGenerationFailed(scenario: .generation, error: error)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("generation", actualProperties["scenario"] as? String)
        assertEqual("custom_login_or_admin_url", actualProperties["cause"] as? String)
    }

    @MainActor
    func test_password_generation_failed_event_is_tracked_upon_any_error() {
        // When
        let error = MockError.anyError
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let expectedEvent = WooAnalyticsEvent.ApplicationPassword.applicationPasswordGenerationFailed(scenario: .generation, error: error)

        XCTAssert(analyticsProvider.receivedEvents.contains(where: { $0 == expectedEvent.statName.rawValue }))

        guard let actualProperties = analyticsProvider.receivedProperties.first(where: { $0.keys.contains("scenario")
        }) else {
            return XCTFail("Expected properties were not logged")
        }

        assertEqual("generation", actualProperties["scenario"] as? String)
        assertEqual("other", actualProperties["cause"] as? String)
    }

    @MainActor
    func test_password_generation_failed_event_when_saved_password_was_rejected_then_tracks_regeneration_path_and_foreground() throws {
        // Given
        applicationStateProvider.state = .inactive
        let error = ApplicationPasswordUseCaseError.unauthorizedRequest

        // When
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed,
                                    object: error,
                                    userInfo: [ApplicationPasswordGenerationUserInfoKey.path: "/wp-json/wc/v3/orders",
                                               ApplicationPasswordGenerationUserInfoKey.isRegeneration: true])

        // Then
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(properties["scenario"] as? String, "regeneration")
        XCTAssertEqual(properties["cause"] as? String, "authorization_failed")
        XCTAssertEqual(properties["path"] as? String, "/wp-json/wc/v3/orders")
        XCTAssertEqual(properties["is_app_in_foreground"] as? Bool, true)
    }

    @MainActor
    func test_password_generation_failed_event_when_app_is_in_background_then_tracks_app_not_in_foreground() throws {
        // Given
        applicationStateProvider.state = .background

        // When
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: MockError.anyError, userInfo: nil)

        // Then
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(properties["is_app_in_foreground"] as? Bool, false)
    }

    @MainActor
    func test_password_generation_failed_event_when_site_rejects_credentials_then_tracks_authorization_failed_cause() throws {
        // Given
        let error = ApplicationPasswordUseCaseError.siteCredentialsRejected

        // When
        mockNotificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

        // Then
        let properties = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(properties["scenario"] as? String, "generation")
        XCTAssertEqual(properties["cause"] as? String, "authorization_failed")
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
            return MockError.anyError
        } catch {
            return error
        }
    }
}

private class MockNotificationCenter: NotificationCenter { }

private final class MockApplicationStateProvider: @unchecked Sendable {
    var state: UIApplication.State = .active
}
