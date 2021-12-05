import XCTest
@testable import Networking


/// TelemetryRemote Unit Tests
///
class TelemetryRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    /// Verifies that sendTelemetry properly accepts null response.
    ///
    func test_sendTelemetry_properly_accepts_null_response() throws {
        // Given
        let remote = TelemetryRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "tracker", filename: "null-data")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    /// Verifies that sendTelemetry properly accepts non-null response.
    ///
    func test_sendTelemetry_properly_accepts_non_null_response() throws {
        // Given
        let remote = TelemetryRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "tracker", filename: "generic_success_data")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    /// Verifies that sendTelemetry properly relays Networking Layer errors.
    ///
    func test_sendTelemetry_properly_relays_networking_errors() {
        // Given
        let remote = TelemetryRemote(network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2") { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
