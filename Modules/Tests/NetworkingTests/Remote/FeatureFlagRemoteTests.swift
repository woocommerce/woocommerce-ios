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

    // MARK: - RemoteFeatureFlag rawValue mapping

    func test_rawValue_when_woo_mobile_ai_assistant_then_maps_to_wooAIAssistant_case() {
        // Given
        let key = "woo_mobile_ai_assistant"

        // When
        let flag = RemoteFeatureFlag(rawValue: key)

        // Then
        XCTAssertEqual(flag, .wooAIAssistant)
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
