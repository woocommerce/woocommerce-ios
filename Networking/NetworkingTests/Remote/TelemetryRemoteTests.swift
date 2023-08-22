import XCTest
@testable import Networking


/// TelemetryRemote Unit Tests
///
final class TelemetryRemoteTests: XCTestCase {

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
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2", installationDate: nil) { result in
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
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2", installationDate: nil) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    /// Verifies that sendTelemetry properly accepts non-null response without data envelope.
    ///
    func test_sendTelemetry_properly_accepts_non_null_response_without_data_envelope() throws {
        // Given
        let remote = TelemetryRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "tracker", filename: "generic_success")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2", installationDate: nil) { result in
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
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2", installationDate: nil) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }

    // MARK: - `installation_date` parameter

    func test_sendTelemetry_includes_installation_date_parameter_in_ISO8601_format() throws {
        // Given
        let remote = TelemetryRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "tracker", filename: "null-data")
        // Tuesday, August 8, 2023 3:49:57 AM
        let installationDate = Date(timeIntervalSince1970: 1691466597)

        // When
        waitFor { promise in
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2", installationDate: installationDate) { result in
                promise(())
            }
        }

        // Then
        XCTAssertEqual(network.queryParametersDictionary?["installation_date"] as? String, "2023-08-08T03:49:57Z")
    }

    func test_sendTelemetry_does_not_include_installation_date_parameter_when_installationDate_is_nil() throws {
        // Given
        let remote = TelemetryRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "tracker", filename: "null-data")

        // When
        waitFor { promise in
            remote.sendTelemetry(for: self.sampleSiteID, versionString: "1.2", installationDate: nil) { result in
                promise(())
            }
        }

        // Then
        XCTAssertNil(network.queryParametersDictionary?["installation_date"])
    }
}
