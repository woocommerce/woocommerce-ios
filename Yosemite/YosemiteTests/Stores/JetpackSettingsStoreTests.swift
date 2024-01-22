import XCTest
@testable import Networking
@testable import Yosemite

final class JetpackSettingsStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    override func setUp() {
        dispatcher = Dispatcher()
        network = MockNetwork()
        storageManager = MockStorageManager()
    }

    func test_updateJetpackModule_returns_success_result() throws {
        // Given
        let store = JetpackSettingsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "jetpack/v4/settings", filename: "jetpack-settings-success")

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = JetpackSettingsAction.enableJetpackModule(.stats, siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_updateJetpackModule_returns_properly_relays_errors() throws {
        // Given
        let store = JetpackSettingsStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "jetpack/v4/settings", error: error)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            let action = JetpackSettingsAction.enableJetpackModule(.stats, siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, error)
    }
}
