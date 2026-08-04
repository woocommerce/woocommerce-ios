import TestKit
import XCTest
@testable import Networking
@testable import NetworkingCore

final class FeatureFlagRemoteTests: XCTestCase {
    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network = MockNetwork()
        network.removeAllSimulatedResponses()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - Load All Feature Flag Tests

    func test_loadAllFeatureFlags_returns_all_known_flags() async throws {
        // Given
        let remote = FeatureFlagRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "mobile/feature-flags", filename: "feature-flags-load-all")

        // When
        let featureFlags = try await remote.loadAllFeatureFlags()

        // Then
        XCTAssertEqual(featureFlags, [
            .storeCreationCompleteNotification: false
        ])
    }

    func test_loadAllFeatureFlags_returns_empty_dictionary_when_response_does_not_include_known_flags() async throws {
        // Given
        let remote = FeatureFlagRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "mobile/feature-flags", filename: "feature-flags-load-all-with-missing-values")

        // When
        let featureFlags = try await remote.loadAllFeatureFlags()

        // Then
        XCTAssert(featureFlags.isEmpty)
    }

    func test_loadAllFeatureFlags_properly_handles_errors() async throws {
        // Given
        let remote = FeatureFlagRemote(network: network)

        // When
        await assertThrowsError({ _ = try await remote.loadAllFeatureFlags() }, errorAssert: {
            // Then
            ($0 as? NetworkError) == .notFound()
        })
    }

    @MainActor
    func test_loadAllFeatureFlags_when_no_device_id_is_stored_then_sends_a_generated_device_id_and_persists_it() async throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "FeatureFlagRemoteTests.\(UUID().uuidString)"))
        let remote = FeatureFlagRemote(network: network, userDefaults: userDefaults)
        network.simulateResponse(requestUrlSuffix: "mobile/feature-flags", filename: "feature-flags-load-all")

        // When
        _ = try await remote.loadAllFeatureFlags()

        // Then
        let queryParameters = try XCTUnwrap(network.queryParametersDictionary)
        let sentDeviceID = try XCTUnwrap(queryParameters["device_id"] as? String)
        XCTAssertFalse(sentDeviceID.isEmpty)
        XCTAssertEqual(userDefaults.string(forKey: "FeatureFlagDeviceID"), sentDeviceID)
    }

    @MainActor
    func test_loadAllFeatureFlags_when_a_device_id_is_stored_then_sends_the_stored_device_id() async throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: "FeatureFlagRemoteTests.\(UUID().uuidString)"))
        userDefaults.set("stored-device-id", forKey: "FeatureFlagDeviceID")
        let remote = FeatureFlagRemote(network: network, userDefaults: userDefaults)
        network.simulateResponse(requestUrlSuffix: "mobile/feature-flags", filename: "feature-flags-load-all")

        // When
        _ = try await remote.loadAllFeatureFlags()

        // Then
        let queryParameters = try XCTUnwrap(network.queryParametersDictionary)
        XCTAssertEqual(queryParameters["device_id"] as? String, "stored-device-id")
    }

    // MARK: - RemoteFeatureFlag rawValue mapping

    func test_rawValue_when_woo_mobile_ai_assistant_then_maps_to_wooAIAssistant_case() {
        // Given
        let key = "woo_mobile_ai_assistant"

        // When
        let flag = RemoteFeatureFlag(rawValue: key)

        // Then
        XCTAssertEqual(flag, .wooAIAssistant)
    }

    func test_rawValue_when_woo_ipp_australia_woopayments_then_maps_to_inPersonPaymentsAustraliaWooPayments_case() {
        // Given
        let key = "woo_ipp_australia_woopayments"

        // When
        let flag = RemoteFeatureFlag(rawValue: key)

        // Then
        XCTAssertEqual(flag, .inPersonPaymentsAustraliaWooPayments)
    }

    func test_rawValue_when_smarter_notifications_then_maps_to_smarterNotifications_case() {
        // Given
        let key = "smarter_notifications"

        // When
        let flag = RemoteFeatureFlag(rawValue: key)

        // Then
        XCTAssertEqual(flag, .smarterNotifications)
    }

    func test_rawValue_when_unknown_key_then_returns_nil() {
        // Given
        let key = "definitely_not_a_known_flag"

        // When
        let flag = RemoteFeatureFlag(rawValue: key)

        // Then
        XCTAssertNil(flag)
    }
}
