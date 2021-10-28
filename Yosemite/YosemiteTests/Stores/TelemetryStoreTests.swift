import XCTest
@testable import Yosemite
@testable import Networking


/// SettingStoreTests Unit Tests
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

    // MARK: - TelemetryAction.postTelemetry

    func test_postTelemetry_action_accepts_null_data_response() {
        // Given
        let store = TelemetryStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "tracker", filename: "null-data")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = TelemetryAction.postTelemetry(siteID: self.sampleSiteID, versionString: "1.2") { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_postTelemetry_action_properly_relays_errors() {
        // Given
        let store = TelemetryStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = TelemetryAction.postTelemetry(siteID: self.sampleSiteID, versionString: "1.2") { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
