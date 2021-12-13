import XCTest
@testable import Networking

class FeatureFlagRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load All Feature Flag Tests

    /// Verifies that loadAllFeatureFlags properly parses the `feature-flags-load-all` sample response.
    ///
    func testLoadAllFeatureFlagsProperlyReturnsParsedFeatureFlags() throws {
        // Given
        let remote = FeatureFlagsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "mobile/feature-flags", filename: "feature-flags-load-all")

        // When
        var result: Result<FeatureFlagList, Error>?
        waitForExpectation { expectation in
            remote.loadAllFeatureFlags(forDeviceId: UUID().uuidString) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        let featureFlags = try XCTUnwrap(result?.get())
        XCTAssert(featureFlags.count == 2)
    }

    func testLoadAllFeatureFlagsProperlyHandlesErrors() throws {
        // Given
        let remote = FeatureFlagsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "mobile/feature-flags", filename: "generic_error")

        // When
        var result: Result<FeatureFlagList, Error>?
        waitForExpectation { expectation in
            remote.loadAllFeatureFlags(forDeviceId: UUID().uuidString) { aResult in
                result = aResult
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertTrue(try XCTUnwrap(result).isFailure)
    }
}
