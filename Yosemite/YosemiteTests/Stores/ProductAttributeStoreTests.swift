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

    func test_synchronize_product_attributes_returns_error_upon_error_response() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "products/attributes", filename: "generic_error")
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

    func test_add_product_attribute_returns_error_upon_empty_response() throws {
        // Given
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

    func test_update_product_attribute_stored_attribute_upon_successful_response() throws {
        // Given
        let initialAttribute = sampleProductAttribute(attributeID: 1)
        storageManager.insertSampleProductAttribute(readOnlyProductAttribute: initialAttribute)
        network.simulateResponse(requestUrlSuffix: "products/attributes/1", filename: "product-attribute-update")
        XCTAssertEqual(storedProductAttributesCount, 1)

        // When
        let result: Result<Networking.ProductAttribute, Error> = try waitFor { promise in
            let action = ProductAttributeAction.updateProductAttribute(siteID: self.sampleSiteID, productAttributeID: 1, name: "Color") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedProductAttributesCount, 1)
        let updatedAttribute = viewStorage.loadProductAttribute(siteID: sampleSiteID, attributeID: initialAttribute.attributeID)
        XCTAssertEqual(initialAttribute.siteID, updatedAttribute?.siteID)
        XCTAssertEqual(initialAttribute.attributeID, updatedAttribute?.attributeID)
        XCTAssertNotEqual(initialAttribute.name, updatedAttribute?.name)
        XCTAssertNotEqual(initialAttribute.visible, updatedAttribute?.visible)
        XCTAssertNotEqual(initialAttribute.variation, updatedAttribute?.variation)
        XCTAssertEqual(initialAttribute.options, updatedAttribute?.options)
    }

    func test_update_product_attribute_returns_error_upon_response_error() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "products/attributes/1", filename: "generic_error")
        XCTAssertEqual(storedProductAttributesCount, 0)

        // When
        let result: Result<Networking.ProductAttribute, Error> = try waitFor { promise in
            let action = ProductAttributeAction.updateProductAttribute(siteID: self.sampleSiteID, productAttributeID: 1, name: "Color") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(storedProductAttributesCount, 0)
    }

    func test_update_product_attribute_returns_error_upon_empty_response() throws {
        // Given
        XCTAssertEqual(storedProductAttributesCount, 0)

        // When
        let result: Result<Networking.ProductAttribute, Error> = try waitFor { promise in
            let action = ProductAttributeAction.updateProductAttribute(siteID: self.sampleSiteID, productAttributeID: 1, name: "Color") { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(storedProductAttributesCount, 0)
    }

    func test_delete_product_attribute_stored_attribute_upon_successful_response() throws {
        // Given
        let initialAttribute = sampleProductAttribute(attributeID: 1)
        storageManager.insertSampleProductAttribute(readOnlyProductAttribute: initialAttribute)
        network.simulateResponse(requestUrlSuffix: "products/attributes/1", filename: "product-attribute-delete")
        XCTAssertEqual(storedProductAttributesCount, 1)

        // When
        let result: Result<Networking.ProductAttribute, Error> = try waitFor { promise in
            let action = ProductAttributeAction.deleteProductAttribute(siteID: self.sampleSiteID, productAttributeID: 1) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storedProductAttributesCount, 0)
    }

    func test_delete_product_attribute_returns_error_upon_response_error() throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "products/attributes/1", filename: "generic_error")
        XCTAssertEqual(storedProductAttributesCount, 0)

        // When
        let result: Result<Networking.ProductAttribute, Error> = try waitFor { promise in
            let action = ProductAttributeAction.deleteProductAttribute(siteID: self.sampleSiteID, productAttributeID: 1) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(storedProductAttributesCount, 0)
    }

    func test_delete_product_attribute_returns_error_upon_empty_response() throws {
        // Given
        XCTAssertEqual(storedProductAttributesCount, 0)

        // When
        let result: Result<Networking.ProductAttribute, Error> = try waitFor { promise in
            let action = ProductAttributeAction.deleteProductAttribute(siteID: self.sampleSiteID, productAttributeID: 1) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(storedProductAttributesCount, 0)
    }
}

private extension ProductAttributeStoreTests {
    func sampleProductAttribute(attributeID: Int64) -> Networking.ProductAttribute {
        return Networking.ProductAttribute(siteID: sampleSiteID,
                                           attributeID: attributeID,
                                           name: "Sample",
                                           position: 0,
                                           visible: false,
                                           variation: false,
                                           options: [])
    }
}
