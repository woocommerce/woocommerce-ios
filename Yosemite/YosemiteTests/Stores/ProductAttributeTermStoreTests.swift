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
        store.pageSizeRequest = 3
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
        let result: Result<Void, ProductAttributeTermActionError> = waitFor { promise in
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
        let result: Result<Void, ProductAttributeTermActionError> = waitFor { promise in
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

    func test_synchronizeProductAttributeTerms_updates_previously_stored_terms() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms")
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms-empty")

        let sampleTermID: Int64 = 27
        let initialTerm = insertProductAttributeTerm(termID: sampleTermID)

        // When
        let result: Result<Void, ProductAttributeTermActionError> = waitFor { promise in
            let action = ProductAttributeTermAction.synchronizeProductAttributeTerms(siteID: self.sampleSiteID,
                                                                                     attributeID: self.sampleAttributeID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        let storedTerm = viewStorage.loadProductAttributeTerm(siteID: sampleSiteID, termID: sampleTermID, attributeID: sampleAttributeID)
        let readOnlyTerm = try XCTUnwrap(storedTerm?.toReadOnly())
        XCTAssertNotEqual(initialTerm, readOnlyTerm)
        XCTAssertFalse(result.isFailure)
    }

    func test_synchronizeProductAttributeTerms_deletes_stale_terms() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms")
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "product-attribute-terms-empty")

        let sampleTermID: Int64 = 10
        insertProductAttributeTerm(termID: sampleTermID)

        // When
        let result: Result<Void, ProductAttributeTermActionError> = waitFor { promise in
            let action = ProductAttributeTermAction.synchronizeProductAttributeTerms(siteID: self.sampleSiteID,
                                                                                     attributeID: self.sampleAttributeID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertNil(viewStorage.loadProductAttributeTerm(siteID: sampleSiteID, termID: sampleTermID, attributeID: sampleAttributeID))
        XCTAssertEqual(storedProductAttributeTermsCount, 3)
        XCTAssertFalse(result.isFailure)
    }

    func test_createProductAttributeTerm_stores_term_correctly() throws {
        // Given
        let expectedTerm = ProductAttributeTerm(siteID: sampleSiteID, termID: 23, name: "XXS", slug: "xxs", count: 1)
        network.simulateResponse(requestUrlSuffix: sampleTermsPath, filename: "attribute-term")

        // When
        let result: Result<Yosemite.ProductAttributeTerm, Error> = waitFor { promise in
            let action = ProductAttributeTermAction.createProductAttributeTerm(siteID: self.sampleSiteID,
                                                                               attributeID: self.sampleAttributeID,
                                                                               name: "XXS") { result in
                promise(result)
            }
            self.store.onAction(action)
        }


        // Then
        let storedTerm = try XCTUnwrap(viewStorage.loadProductAttributeTerm(siteID: sampleSiteID, termID: 23, attributeID: sampleAttributeID))
        XCTAssertEqual(expectedTerm, storedTerm.toReadOnly())
        XCTAssertNotNil(storedTerm.attribute)
        XCTAssertFalse(result.isFailure)
    }
}

// MARK: Helpers
private extension ProductAttributeTermStoreTests {
    @discardableResult
    func insertProductAttribute() -> Yosemite.ProductAttribute {
        let attribute = ProductAttribute(siteID: sampleSiteID,
                                         attributeID: sampleAttributeID,
                                         name: "attribute",
                                         position: 0,
                                         visible: true,
                                         variation: true,
                                         options: [])
        storageManager.insertSampleProductAttribute(readOnlyProductAttribute: attribute)
        return attribute
    }

    @discardableResult
    func insertProductAttributeTerm(termID: Int64) -> Yosemite.ProductAttributeTerm {
        let term = ProductAttributeTerm(siteID: sampleSiteID, termID: termID, name: "", slug: "", count: 0)
        storageManager.insertSampleProductAttributeTerm(readOnlyTerm: term, onAttributeWithID: sampleAttributeID)
        return term
    }
}
