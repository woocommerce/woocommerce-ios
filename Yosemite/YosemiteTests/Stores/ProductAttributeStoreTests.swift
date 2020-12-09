import XCTest
@testable import Yosemite
@testable import Storage
@testable import Networking


/// ProductAttributeStore Unit Tests
///
final class ProductAttributeStoreTests: XCTestCase {
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

    /// Convenience Property: Returns stored product attributes count.
    ///
    private var storedProductAttributesCount: Int {
        return viewStorage.countObjects(ofType: Storage.ProductAttribute.self)
    }

    /// Store
    ///
    private var store: ProductAttributeStore!

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 123

    /// Testing Page Number
    ///
    private let defaultPageNumber = 1

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        network = MockNetwork(useResponseQueue: true)
        storageManager = MockStorageManager()
        store = ProductAttributeStore(dispatcher: Dispatcher(),
                                     storageManager: storageManager,
                                     network: network)
    }

    override func tearDown() {
        store = nil
        network = nil
        storageManager = nil

        super.tearDown()
    }

    func test_synchronize_product_attributes_returns_attributes_upon_successful_response() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "products/attributes", filename: "product-attributes-all")
        XCTAssertEqual(storedProductAttributesCount, 0)

        // When
        let result: Result<[Networking.ProductAttribute], Error> = try waitFor { promise in
            let action = ProductAttributeAction.synchronizeProductAttributes(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedProductAttributesCount, 2)
    }

    func test_synchronize_product_attributes_updates_stored_attributes_upon_successful_response() throws {
        // Given
        let initialAttribute = sampleProductAttribute(attributeID: 1)
        storageManager.insertSampleProductAttribute(readOnlyProductAttribute: initialAttribute)
        network.simulateResponse(requestUrlSuffix: "products/attributes", filename: "product-attributes-all")
        XCTAssertEqual(storedProductAttributesCount, 1)

        // When
        let result: Result<[Networking.ProductAttribute], Error> = try waitFor { promise in
            let action = ProductAttributeAction.synchronizeProductAttributes(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedProductAttributesCount, 2)
        let updatedAttribute = viewStorage.loadProductAttribute(siteID: sampleSiteID, attributeID: initialAttribute.attributeID)
        XCTAssertEqual(initialAttribute.siteID, updatedAttribute?.siteID)
        XCTAssertEqual(initialAttribute.attributeID, updatedAttribute?.attributeID)
        XCTAssertNotEqual(initialAttribute.name, updatedAttribute?.name)
        XCTAssertNotEqual(initialAttribute.visible, updatedAttribute?.visible)
        XCTAssertNotEqual(initialAttribute.variation, updatedAttribute?.variation)
        XCTAssertEqual(initialAttribute.options, updatedAttribute?.options)
    }

    func test_synchronize_product_attributes_returns_error_upon_empty_response() throws {
        // Given
        XCTAssertEqual(storedProductAttributesCount, 0)

        // When
        let result: Result<[Networking.ProductAttribute], Error> = try waitFor { promise in
            let action = ProductAttributeAction.synchronizeProductAttributes(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertEqual(storedProductAttributesCount, 0)
        XCTAssertTrue(result.isFailure)
    }

    func test_add_product_attribute_stored_attribute_upon_successful_response() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "products/attributes", filename: "product-attribute-create")
        XCTAssertEqual(storedProductAttributesCount, 0)

        // When
        let result: Result<Networking.ProductAttribute, Error> = try waitFor { promise in
            let action = ProductAttributeAction.addProductAttribute(siteID: self.sampleSiteID, name: "Color") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedProductAttributesCount, 1)
        let addedAttribute = viewStorage.loadProductAttribute(siteID: sampleSiteID, attributeID: 1)
        XCTAssertNotNil(addedAttribute)
        XCTAssertEqual(addedAttribute?.siteID, sampleSiteID)
        XCTAssertEqual(addedAttribute?.attributeID, 1)
        XCTAssertEqual(addedAttribute?.name, "Color")
        XCTAssertEqual(addedAttribute?.visible, true)
        XCTAssertEqual(addedAttribute?.variation, true)
        XCTAssertEqual(addedAttribute?.options, [])
    }

    func test_add_product_attribute_returns_error_upon_response_error() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "products/attributes", filename: "generic_error")
        XCTAssertEqual(storedProductAttributesCount, 0)

        // When
        let result: Result<Networking.ProductAttribute, Error> = try waitFor { promise in
            let action = ProductAttributeAction.addProductAttribute(siteID: self.sampleSiteID, name: "Color") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(storedProductAttributesCount, 0)
    }

//
//    func testAddProductTagReturnsErrorUponResponseError() {
//        // Given a stubed generic-error network response
//        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "generic_error")
//        XCTAssertEqual(storedProductTagsCount, 0)
//
//        // When dispatching a `addProductTags` action
//        var result: Result<[Networking.ProductTag], Error>?
//        waitForExpectation { (exp) in
//            let action = ProductTagAction.addProductTags(siteID: sampleSiteID, tags: ["Round toe", "Flat"]) { (aResult) in
//                result = aResult
//                exp.fulfill()
//            }
//            store.onAction(action)
//        }
//
//        // Then no tags should be stored
//        XCTAssertEqual(storedProductTagsCount, 0)
//        XCTAssertNotNil(result?.failure)
//    }
//
//    func testAddProductTagReturnsErrorUponEmptyResponse() {
//        // Given an empty network response
//        XCTAssertEqual(storedProductTagsCount, 0)
//
//        // When dispatching a `addProductTags` action
//        var result: Result<[Networking.ProductTag], Error>?
//        waitForExpectation { (exp) in
//            let action = ProductTagAction.addProductTags(siteID: sampleSiteID, tags: ["Round toe", "Flat"]) { (aResult) in
//                result = aResult
//                exp.fulfill()
//            }
//            store.onAction(action)
//        }
//
//        // Then no tags should be stored
//        XCTAssertEqual(storedProductTagsCount, 0)
//        XCTAssertNotNil(result?.failure)
//    }
//
//    func testSynchronizeProductTagsDeletesUnusedTags() {
//        // Given some stored product tags without product relationships
//        let sampleTags = (1...5).map { id in
//            return sampleTag(tagID: id)
//        }
//        sampleTags.forEach { tag in
//            storageManager.insertSampleProductTag(readOnlyProductTag: tag)
//        }
//        XCTAssertEqual(storedProductTagsCount, sampleTags.count)
//
//        // When dispatching a `synchronizeAllProductTags` action
//        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-all")
//        network.simulateResponse(requestUrlSuffix: "products/tags", filename: "product-tags-empty")
//
//        var errorResponse: ProductTagActionError?
//        waitForExpectation { (exp) in
//            let action = ProductTagAction.synchronizeAllProductTags(siteID: sampleSiteID) { error in
//                errorResponse = error
//                exp.fulfill()
//            }
//            store.onAction(action)
//        }
//
//        // Then new tag should be stored and old tags should be deleted
//        XCTAssertEqual(storedProductTagsCount, 4)
//        XCTAssertNil(errorResponse)
//    }
//
//    func testDeleteProductTagDeleteStoredTagSuccessfulResponse() {
//        // Given a stubed product tag network response and a product tag stored locally
//        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "product-tags-deleted")
//        storageManager.insertSampleProductTag(readOnlyProductTag: sampleTag(tagID: 35))
//
//        XCTAssertEqual(storedProductTagsCount, 1)
//
//        // When dispatching a `deleteProductTags` action
//        var result: Result<[Yosemite.ProductTag], Error>?
//        waitForExpectation { (exp) in
//            let action = ProductTagAction.deleteProductTags(siteID: sampleSiteID, ids: [35]) { (aResult) in
//                result = aResult
//                exp.fulfill()
//            }
//            store.onAction(action)
//        }
//
//        // Then the tag should be removed
//        XCTAssertEqual(storedProductTagsCount, 0)
//        XCTAssertNil(result?.failure)
//    }
//
//    func testDeleteProductTagReturnsErrorUponResponseError() {
//        // Given a stubed generic-error network response
//        network.simulateResponse(requestUrlSuffix: "products/tags/batch", filename: "generic_error")
//        storageManager.insertSampleProductTag(readOnlyProductTag: sampleTag(tagID: 35))
//        XCTAssertEqual(storedProductTagsCount, 1)
//
//        // When dispatching a `deleteProductTags` action
//        var result: Result<[Yosemite.ProductTag], Error>?
//        waitForExpectation { (exp) in
//            let action = ProductTagAction.deleteProductTags(siteID: sampleSiteID, ids: [35]) { (aResult) in
//                result = aResult
//                exp.fulfill()
//            }
//            store.onAction(action)
//        }
//
//        // Then one tags should be continue to be stored
//        XCTAssertEqual(storedProductTagsCount, 1)
//        XCTAssertNotNil(result?.failure)
//    }
//
//    func testDeleteProductTagReturnsErrorUponEmptyResponse() {
//        // Given an empty network response
//        storageManager.insertSampleProductTag(readOnlyProductTag: sampleTag(tagID: 35))
//        XCTAssertEqual(storedProductTagsCount, 1)
//
//        // When dispatching a `deleteProductTags` action
//        var result: Result<[Yosemite.ProductTag], Error>?
//        waitForExpectation { (exp) in
//            let action = ProductTagAction.deleteProductTags(siteID: sampleSiteID, ids: [35]) { (aResult) in
//                result = aResult
//                exp.fulfill()
//            }
//            store.onAction(action)
//        }
//
//        // Then one tags should be continue to be stored
//        XCTAssertEqual(storedProductTagsCount, 1)
//        XCTAssertNotNil(result?.failure)
//    }
}

private extension ProductAttributeStoreTests {
    func sampleProductAttribute(attributeID: Int64) -> Networking.ProductAttribute {
        return Networking.ProductAttribute(siteID: sampleSiteID, attributeID: attributeID, name: "Sample", position: 0, visible: false, variation: false, options: [])
    }
}
