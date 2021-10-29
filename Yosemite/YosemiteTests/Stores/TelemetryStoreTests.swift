import XCTest
@testable import Yosemite
@testable import Networking


/// TelemetryStore Unit Tests
///
class TelemetryStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123


    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - TelemetryAction.sendTelemetry

    func test_sendTelemetry_action_accepts_null_data_response() {
        // Given
        let store = TelemetryStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "tracker", filename: "null-data")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = TelemetryAction.sendTelemetry(siteID: self.sampleSiteID, versionString: "1.2", telemetryLastReportedTime: nil) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_sendTelemetry_action_throttles_request_within_timeout() {
        // Given
        let store = TelemetryStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let time = Date() - 12*60*60 // half of default timeout

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = TelemetryAction.sendTelemetry(siteID: self.sampleSiteID, versionString: "1.2", telemetryLastReportedTime: time) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? TelemetryError, TelemetryError.requestThrottled)
    }

    func test_sendTelemetry_action_properly_relays_errors() {
        // Given
        let store = TelemetryStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = TelemetryAction.sendTelemetry(siteID: self.sampleSiteID, versionString: "1.2", telemetryLastReportedTime: nil) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
