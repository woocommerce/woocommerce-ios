import XCTest

@testable import Storage

/// Test cases for the `ProductVariation` model.
final class ProductVariationTests: XCTestCase {

    private var storageManager: StorageManagerType!

    private var storage: StorageType! {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = CoreDataManager(name: "WooCommerce", crashLogger: MockCrashLogger())
    }

    override func tearDown() {
        storageManager.reset()
        storageManager = nil
        super.tearDown()
    }

    func test_addToAttributes_adds_the_GenericAttribute_to_the_attributes_list() throws {
        // Given
        let variation = makeProductVariation()

        let attribute = storage.insertNewObject(ofType: GenericAttribute.self)
        attribute.id = 9_818
        attribute.key = "temporibus"
        attribute.value = "quia"

        // When
        variation.addToAttributes(attribute)

        // Then
        XCTAssertEqual(variation.attributes.count, 1)

        let attributeFromList = try XCTUnwrap(variation.attributes.firstObject as? GenericAttribute)
        XCTAssertEqual(attributeFromList.objectID, attribute.objectID)
    }
}

private extension ProductVariationTests {
    /// Makes a `ProductVariation` entity, providing default values for the required properties.
    func makeProductVariation() -> ProductVariation {
        let variation = storage.insertNewObject(ofType: ProductVariation.self)
        variation.dateCreated = Date()
        variation.backordered = false
        variation.backordersAllowed = false
        variation.backordersKey = ""
        variation.permalink = ""
        variation.price = ""
        variation.statusKey = ""
        variation.stockStatusKey = ""
        variation.taxStatusKey = ""
        return variation
    }
}
