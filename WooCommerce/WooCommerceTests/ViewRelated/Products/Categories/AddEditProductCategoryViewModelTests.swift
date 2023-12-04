import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class AddEditProductCategoryViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123

    func test_editingMode_is_add_for_new_category() {
        // Given
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID, existingCategory: nil, parentCategory: nil, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.editingMode, .add)
    }

    func test_editingMode_is_edit_for_existing_category() {
        // Given
        let category = ProductCategory.fake().copy(categoryID: 3, name: "Bags")
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID, existingCategory: category, parentCategory: nil, onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.editingMode, .editing)
    }

    func test_saveEnabled_returns_true_when_adding_new_category_with_non_empty_title() {
        // Given
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID, existingCategory: nil, parentCategory: nil, onCompletion: { _ in })
        XCTAssertTrue(viewModel.categoryTitle.isEmpty)
        XCTAssertFalse(viewModel.saveEnabled)

        // When
        viewModel.categoryTitle = "Food"

        // Then
        XCTAssertTrue(viewModel.saveEnabled)
    }

    func test_saveEnabled_returns_true_when_editing_title_for_existing_category() {
        // Given
        let category = ProductCategory.fake().copy(categoryID: 3, name: "Bags")
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID, existingCategory: category, parentCategory: nil, onCompletion: { _ in })
        XCTAssertFalse(viewModel.saveEnabled)

        // When
        viewModel.categoryTitle = "Clothing"

        // Then
        XCTAssertTrue(viewModel.saveEnabled)
    }

    func test_saveEnabled_returns_true_when_editing_parent_category_for_existing_category() {
        // Given
        let category = ProductCategory.fake().copy(categoryID: 3, name: "Bags")
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID, existingCategory: category, parentCategory: nil, onCompletion: { _ in })
        XCTAssertFalse(viewModel.saveEnabled)

        // When
        viewModel.selectedParentCategory = ProductCategory.fake().copy(categoryID: 1, name: "Apparel")

        // Then
        XCTAssertTrue(viewModel.saveEnabled)
    }

    func test_saveCategory_invokes_addProductCategory_when_adding_new_category() async throws {
        // Given
        let title = "Yarn"
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID,
                                                        existingCategory: nil,
                                                        parentCategory: nil,
                                                        stores: stores,
                                                        onCompletion: { _ in })

        // When
        viewModel.categoryTitle = title
        viewModel.selectedParentCategory = ProductCategory.fake().copy(categoryID: 1)
        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .addProductCategory(siteID, name, parentID, onCompletion):
                // Then
                XCTAssertEqual(siteID, self.sampleSiteID)
                XCTAssertEqual(name, title)
                XCTAssertEqual(parentID, 1)
                onCompletion(.success(.fake()))
            case .updateProductCategory:
                XCTFail("Should not trigger updating for new product category!")
            default:
                break
            }
        }
        try await viewModel.saveCategory()
    }

    func test_onCompletion_is_invoked_upon_adding_success() async throws {
        // Given
        var newCategory: ProductCategory?
        let expectedCategory = ProductCategory.fake().copy(categoryID: 3, parentID: 1, name: "Yarn")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID,
                                                        existingCategory: nil,
                                                        parentCategory: nil,
                                                        stores: stores,
                                                        onCompletion: { newCategory = $0 })

        // When
        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .addProductCategory(_, _, _, onCompletion):
                onCompletion(.success(expectedCategory))
            default:
                break
            }
        }
        try await viewModel.saveCategory()

        // Then
        XCTAssertEqual(newCategory, expectedCategory)
    }

    func test_saveCategory_invokes_updateProductCategory_for_existing_category() async throws {
        // Given
        let title = "Yarn"
        let category = ProductCategory.fake().copy(categoryID: 3, name: "Bags")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID,
                                                        existingCategory: category,
                                                        parentCategory: nil,
                                                        stores: stores,
                                                        onCompletion: { _ in })

        // When
        viewModel.categoryTitle = title
        viewModel.selectedParentCategory = ProductCategory.fake().copy(categoryID: 1)
        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case .addProductCategory:
                XCTFail("Should not trigger updating for new product category!")
            case let .updateProductCategory(category, onCompletion):
                // Then
                XCTAssertEqual(category.name, title)
                XCTAssertEqual(category.slug, "")
                XCTAssertEqual(category.parentID, 1)
                onCompletion(.success(.fake()))
            default:
                break
            }
        }
        try await viewModel.saveCategory()
    }

    func test_onCompletion_is_invoked_upon_updating_success() async throws {
        // Given
        var newCategory: ProductCategory?
        let expectedCategory = ProductCategory.fake().copy(categoryID: 3, parentID: 1, name: "Yarn")
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = AddEditProductCategoryViewModel(siteID: sampleSiteID,
                                                        existingCategory: .fake(),
                                                        parentCategory: nil,
                                                        stores: stores,
                                                        onCompletion: { newCategory = $0 })

        // When
        stores.whenReceivingAction(ofType: ProductCategoryAction.self) { action in
            switch action {
            case let .updateProductCategory(_, onCompletion):
                onCompletion(.success(expectedCategory))
            default:
                break
            }
        }
        try await viewModel.saveCategory()

        // Then
        XCTAssertEqual(newCategory, expectedCategory)
    }
}
