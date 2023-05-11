import TestKit
import XCTest
@testable import Networking

final class FeatureFlagsRemoteTests: XCTestCase {
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
        let remote = FeatureFlagsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "mobile/feature-flags", filename: "feature-flags-load-all")

        // When
        let featureFlags = try await remote.loadAllFeatureFlags()

        // Then
        XCTAssertEqual(featureFlags, [
            .storeCreationCompleteNotification: false,
            .oneDayAfterStoreCreationNameWithoutFreeTrial: false,
            .oneDayBeforeFreeTrialExpiresNotification: false,
            .oneDayAfterFreeTrialExpiresNotification: false
        ])
    }

    func test_loadAllFeatureFlags_returns_empty_dictionary_when_response_does_not_include_known_flags() async throws {
        // Given
        let remote = FeatureFlagsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "mobile/feature-flags", filename: "feature-flags-load-all-with-missing-values")

        // When
        let featureFlags = try await remote.loadAllFeatureFlags()

        // Then
        XCTAssert(featureFlags.isEmpty)
    }

    func test_loadAllFeatureFlags_properly_handles_errors() async throws {
        // Given
        let remote = FeatureFlagsRemote(network: network)

        // When
        await assertThrowsError({ _ = try await remote.loadAllFeatureFlags() }, errorAssert: {
            // Then
            ($0 as? NetworkError) == .notFound
        })
    }
}
