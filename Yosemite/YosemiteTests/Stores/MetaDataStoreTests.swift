import XCTest
@testable import Networking
@testable import Storage
@testable import Yosemite

final class MetaDataStoreTests: XCTestCase {
    private var network: MockNetwork!
    private var remote: MockMetaDataRemote!
    private var storageManager: MockStorageManager!
    private var storage: StorageType! {
        storageManager.viewStorage
    }
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }
    private let sampleSiteID: Int64 = 1234
    private let sampleOrderID: Int64 = 1
    private let sampleProductID: Int64 = 2
    private let newMetadataArray = [["id": 1234, "key": "newValue"]]
    private let returnMetaDataArray = [MetaData.fake().copy(metadataID: 1234, key: "key", value: "newValue")]

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        storageManager = MockStorageManager()
        remote = MockMetaDataRemote()
    }

    override func tearDown() {
        network = nil
        storageManager = nil
        remote = nil
        super.tearDown()
    }

    // MARK: - Update Order MetaData

    func test_updateOrderMetaData_is_successful_when_updating_successfully() throws {
        // Given
        remote.whenUpdatingMetaData(thenReturn: .success(returnMetaDataArray))
        let store = MetaDataStore(dispatcher: Dispatcher(),
                                  storageManager: storageManager,
                                  network: network,
                                  remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(MetaDataAction.updateOrderMetaData(siteID: self.sampleSiteID,
                                                              orderID: self.sampleOrderID,
                                                              metadata: newMetadataArray,
                                                              onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        let updatedMetaData = try result.get()
        XCTAssertEqual(updatedMetaData.count, 1)
        XCTAssertEqual(updatedMetaData.first?.key, "key")
        XCTAssertEqual(updatedMetaData.first?.value, "newValue")
    }

    func test_updateOrderMetaData_returns_error_on_failure() throws {
        // Given
        let metadata = [["key": "newValue"]]
        remote.whenUpdatingMetaData(thenReturn: .failure(NetworkError.timeout()))
        let store = MetaDataStore(dispatcher: Dispatcher(),
                                  storageManager: storageManager,
                                  network: network,
                                  remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(MetaDataAction.updateOrderMetaData(siteID: self.sampleSiteID, orderID: self.sampleOrderID, metadata: metadata, onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    // MARK: - Update Product MetaData

    func test_updateProductMetaData_is_successful_when_updating_successfully() throws {
        // Given
        remote.whenUpdatingMetaData(thenReturn: .success(returnMetaDataArray))
        let store = MetaDataStore(dispatcher: Dispatcher(),
                                  storageManager: storageManager,
                                  network: network,
                                  remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(MetaDataAction.updateProductMetaData(siteID: self.sampleSiteID,
                                                                productID: self.sampleProductID,
                                                                metadata: newMetadataArray,
                                                                onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        let updatedMetaData = try result.get()
        XCTAssertEqual(updatedMetaData.count, 1)
        XCTAssertEqual(updatedMetaData.first?.key, "key")
        XCTAssertEqual(updatedMetaData.first?.value, "newValue")
    }

    func test_updateProductMetaData_returns_error_on_failure() throws {
        // Given
        let metadata = [["key": "value"]]
        remote.whenUpdatingMetaData(thenReturn: .failure(NetworkError.timeout()))
        let store = MetaDataStore(dispatcher: Dispatcher(),
                                  storageManager: storageManager,
                                  network: network,
                                  remote: remote)

        // When
        let result = waitFor { promise in
            store.onAction(MetaDataAction.updateProductMetaData(siteID: self.sampleSiteID,
                                                                productID: self.sampleProductID,
                                                                metadata: metadata,
                                                                onCompletion: { result in
                promise(result)
            }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }
}
