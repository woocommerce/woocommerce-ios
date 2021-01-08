import XCTest

@testable import Yosemite
@testable import Storage
@testable import Networking


final class ProductAttributeTermStoreTests: XCTestCase {
    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Convenience Property: Returns stored product attribute terms count.
    ///
    private var storedProductAttributeTermsCount: Int {
        return viewStorage.countObjects(ofType: Storage.ProductAttributeTerm.self)
    }

    /// Store
    ///
    private var store: ProductAttributeTermStore!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing attribute ID
    ///
    private let sampleAttributeID: Int64 = 12

    /// Terms endpoint path
    ///
    private var sampleTermsPath: String {
        "products/attributes/\(sampleAttributeID)/terms"
    }

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    override func setUp() {
        super.setUp()
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        store = ProductAttributeTermStore(dispatcher: Dispatcher(),
                                          storageManager: storageManager,
                                          network: network)
        insertProductAttribute()
    }

    override func tearDown() {
        store = nil
        network = nil
        storageManager = nil

        super.tearDown()
    }

    func test_synchronizeProductAttributeTerms_stores_single_page_terms() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms")
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms-empty")
        XCTAssertEqual(storedProductAttributeTermsCount, 0)

        // When
        let result: Result<Void, ProductAttributeTermActionError> = try waitFor { promise in
            let action = ProductAttributeTermAction.synchronizeProductAttributeTerms(siteID: self.sampleSiteID,
                                                                                     attributeID: self.sampleAttributeID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(storedProductAttributeTermsCount, 3)
        XCTAssertFalse(result.isFailure)
    }

    func test_synchronizeProductAttributeTerms_stores_multiple_page_terms() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms")
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms-extra")
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms-empty")
        XCTAssertEqual(storedProductAttributeTermsCount, 0)

        // When
        let result: Result<Void, ProductAttributeTermActionError> = try waitFor { promise in
            let action = ProductAttributeTermAction.synchronizeProductAttributeTerms(siteID: self.sampleSiteID,
                                                                                     attributeID: self.sampleAttributeID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(storedProductAttributeTermsCount, 6)
        XCTAssertFalse(result.isFailure)
    }
}

// MARK: Helpers
private extension ProductAttributeTermStoreTests {
    func insertProductAttribute() {
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: sampleAttributeID,
                                         name: "attribute",
                                         position: 0,
                                         visible: true,
                                         variation: true,
                                         options: [])
        let storedAttribute = viewStorage.insertNewObject(ofType: ProductAttribute.self)
        storedAttribute.update(with: attribute)
        viewStorage.saveIfNeeded()
    }
}
