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
            store.onAction(MetaDataAction.updateMetaData(siteID: self.sampleSiteID,
                                                         parentItemID: self.sampleOrderID,
                                                         metaDataType: .order,
                                                         metadata: self.newMetadataArray,
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
            store.onAction(MetaDataAction.updateMetaData(siteID: self.sampleSiteID,
                                                         parentItemID: self.sampleOrderID,
                                                         metaDataType: .order,
                                                         metadata: metadata,
                                                         onCompletion: { result in
                                                             promise(result)
                                                         }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }

    func test_updateOrderMetaData_removes_deleted_items() {
        // Given
        let metaData = [MetaData.fake().copy(metadataID: 1, key: "key", value: "value"),
                        MetaData.fake().copy(metadataID: 2, key: "key", value: "value")]
        let order = Yosemite.Order.fake().copy(siteID: sampleSiteID, orderID: sampleOrderID, customFields: metaData)
        storageManager.insertSampleOrder(readOnlyOrder: order)

        remote.whenUpdatingMetaData(thenReturn: .success([metaData.last!]))
        let store = MetaDataStore(dispatcher: Dispatcher(),
                                  storageManager: storageManager,
                                  network: network,
                                  remote: remote)

        // When
        waitFor { promise in
            store.onAction(MetaDataAction.updateMetaData(siteID: self.sampleSiteID,
                                                         parentItemID: self.sampleOrderID,
                                                         metaDataType: .order,
                                                         metadata: [["id": 1, "value": nil]],
                                                         onCompletion: { _ in promise(()) }))
        }

        // Then
        let updatedOrder = storageManager.viewStorage.loadOrder(siteID: order.siteID, orderID: order.orderID)?.toReadOnly()
        XCTAssertEqual(updatedOrder?.customFields.count, 1)
        XCTAssertEqual(updatedOrder?.customFields.first, metaData.last)
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
            store.onAction(MetaDataAction.updateMetaData(siteID: self.sampleSiteID,
                                                         parentItemID: self.sampleOrderID,
                                                         metaDataType: .order,
                                                         metadata: self.newMetadataArray,
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
            store.onAction(MetaDataAction.updateMetaData(siteID: self.sampleSiteID,
                                                         parentItemID: self.sampleOrderID,
                                                         metaDataType: .order,
                                                         metadata: metadata,
                                                         onCompletion: { result in
                                                             promise(result)
                                                         }))
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, .timeout())
    }


    func test_updateProductMetaData_removes_deleted_items() {
        // Given
        let metaData = [MetaData.fake().copy(metadataID: 1, key: "key", value: "value"),
                        MetaData.fake().copy(metadataID: 2, key: "key", value: "value")]
        let product = Yosemite.Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, customFields: metaData)
        // Insert product with metadata
        storageManager.insertSampleProduct(readOnlyProduct: product)

        remote.whenUpdatingMetaData(thenReturn: .success([metaData.last!]))
        let store = MetaDataStore(dispatcher: Dispatcher(),
                                  storageManager: storageManager,
                                  network: network,
                                  remote: remote)

        // When
        waitFor { promise in
            store.onAction(MetaDataAction.updateMetaData(siteID: self.sampleSiteID,
                                                         parentItemID: self.sampleProductID,
                                                         metaDataType: .product,
                                                         metadata: [["id": 1, "value": nil]],
                                                         onCompletion: { _ in promise(()) }))
        }

        // Then
        let updatedProduct = storageManager.viewStorage.loadProduct(siteID: product.siteID, productID: product.productID)?.toReadOnly()
        XCTAssertEqual(updatedProduct?.customFields.count, 1)
        XCTAssertEqual(updatedProduct?.customFields.first?.key, metaData.last!.key)
    }
}

private extension MockStorageManager {
    func insertSampleMetaData(_ metaData: Networking.MetaData) {
        let storageObj = viewStorage.insertNewObject(ofType: MetaData.self)
        storageObj.update(with: metaData)
    }
}
