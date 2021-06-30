import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// DataStore Unit Tests
///
final class DataStoreTests: XCTestCase {

    /// Mock Dispatcher!
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        network.removeAllSimulatedResponses()
    }

    override func tearDown() {
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
    }

    // MARK: `synchronizeCountries`

    func test_synchronizeCountries_persists_Country_on_success() throws {
        // Given
        let remote = DataRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "data/countries", filename: "countries")
        let store = DataStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<[Yosemite.Country], Error> = waitFor { promise in
            let action = DataAction.synchronizeCountries(siteID: 123) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)

        let persistedCountries = try XCTUnwrap(viewStorage.loadCountries())
        XCTAssertEqual(persistedCountries.count, 3)
        XCTAssertEqual(persistedCountries.first?.code, "AT")
        XCTAssertEqual(persistedCountries.first?.name, "Austria")
        XCTAssertEqual(persistedCountries.first?.states.count, 0)
        XCTAssertEqual(persistedCountries[2].code, "US")
        XCTAssertEqual(persistedCountries[2].name, "United States (US)")

        let states = persistedCountries[2].states.sorted { (lhs, rhs) -> Bool in
            lhs.name < rhs.name
        }
        XCTAssertEqual(states.count, 54)
        XCTAssertEqual(states.first?.code, "AL")
        XCTAssertEqual(states.first?.name, "Alabama")
    }

    func test_synchronizeCountries_returns_error_on_failure() throws {
        // Given
        let remote = DataRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "data/countries", filename: "generic_error")
        let store = DataStore(dispatcher: dispatcher, storageManager: storageManager, network: network, remote: remote)

        // When
        let result: Result<[Yosemite.Country], Error> = waitFor { promise in
            let action = DataAction.synchronizeCountries(siteID: 123) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertNotNil(result.failure)
    }
}
