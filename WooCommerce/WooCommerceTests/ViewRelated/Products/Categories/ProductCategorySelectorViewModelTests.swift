import XCTest
@testable import WooCommerce
@testable import Yosemite
@testable import Storage

final class ProductCategorySelectorViewModelTests: XCTestCase {

    private var storageManager: StorageManagerType!
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        super.tearDown()
        storageManager = nil
    }

    func test_selectedItemsCount_is_correct_with_preselected_items() {
        // Given
        let siteID: Int64 = 123
        let category = Yosemite.ProductCategory(categoryID: 33, siteID: siteID, parentID: 1, name: "Test", slug: "test")
        insert(category)

        // When
        let viewModel = ProductCategorySelectorViewModel(siteID: siteID, selectedCategories: [category.categoryID], storageManager: storageManager) { _ in }

        // Then
        XCTAssertEqual(viewModel.selectedItemsCount, 1)
    }
}

private extension ProductCategorySelectorViewModelTests {
    func insert(_ readOnlyProductCategory: Yosemite.ProductCategory) {
        let category = storage.insertNewObject(ofType: StorageProductCategory.self)
        category.update(with: readOnlyProductCategory)
    }
}
