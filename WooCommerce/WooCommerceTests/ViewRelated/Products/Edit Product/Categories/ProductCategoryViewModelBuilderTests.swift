import XCTest

@testable import WooCommerce
@testable import Yosemite

/// Tests for `ProductCategoryListViewModel.CellViewModelBuilder`.
///
final class ProductCategoryViewModelBuilderTests: XCTestCase {

    /// Sample siteID
    ///
    private let sampleSiteID: Int64 = 123

    func testCategoriesWithoutSubCategoriesPreserveInitialOrder() {
        // Given
        let categories = sampleCategories(initialID: 1, count: 10)

        // When
        let viewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: categories, selectedCategories: [])

        // Then
        let expectedCategoriesNames = categories.map { $0.name }
        let viewModelsNames = viewModels.map { $0.name }
        XCTAssertEqual(expectedCategoriesNames, viewModelsNames)
    }

    func testCategoriesWithSubCategoriesAreFlattenedCorrectly() {
        // Given
        let rootCategories = sampleCategories(initialID: 1, count: 10)
        let subCategories1 = sampleCategories(initialID: 11, parentID: 5, count: 5)
        let subCategories2 = sampleCategories(initialID: 16, parentID: 13, count: 3)
        let allCategories = rootCategories + subCategories1 + subCategories2

        // When
        let viewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: allCategories, selectedCategories: [])

        // Then
        let expectedCategoriesNames: [String] = {
            var expected = rootCategories
            expected.insert(contentsOf: subCategories1, at: 5)
            expected.insert(contentsOf: subCategories2, at: 8)
            return expected.map { $0.name }
        }()
        let viewModelsNames = viewModels.map { $0.name }
        XCTAssertEqual(expectedCategoriesNames, viewModelsNames)
    }

    func testFlattenedCategoriesHaveACorrectIndentationLevel() {
        // Given
        let rootCategories = sampleCategories(initialID: 1, count: 10)
        let subCategories1 = sampleCategories(initialID: 11, parentID: 5, count: 5)
        let subCategories2 = sampleCategories(initialID: 16, parentID: 13, count: 3)
        let allCategories = rootCategories + subCategories1 + subCategories2

        // When
        let viewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: allCategories, selectedCategories: [])

        // Then
        let rootCategoriesNames = rootCategories.map { $0.name }
        let subCategories1Names = subCategories1.map { $0.name }
        let subCategories2Names = subCategories2.map { $0.name }
        for viewModel in viewModels {
            if rootCategoriesNames.contains(viewModel.name) {
                XCTAssertEqual(viewModel.indentationLevel, 0)
            }

            if subCategories1Names.contains(viewModel.name) {
                XCTAssertEqual(viewModel.indentationLevel, 1)
            }

            if subCategories2Names.contains(viewModel.name) {
                XCTAssertEqual(viewModel.indentationLevel, 2)
            }
        }
    }

    func testRootCategoriesAreMarkedAsSelected() {
        // Given
        let categories = sampleCategories(initialID: 1, count: 10)
        let selectedCategories = sampleCategories(initialID: 3, count: 5)

        // When
        let viewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: categories, selectedCategories: selectedCategories)

        // Then
        let selectedCategoryNames = selectedCategories.map { $0.name }
        let selectedViewModelsNames = viewModels.filter { $0.isSelected }.map { $0.name }
        XCTAssertEqual(selectedCategoryNames, selectedViewModelsNames)
    }

    func testSubCategoriesAreMarkedAsSelectec() {
        // Given
        let rootCategories = sampleCategories(initialID: 1, count: 10)
        let subCategories1 = sampleCategories(initialID: 11, parentID: 5, count: 5)
        let selectedCategories = sampleCategories(initialID: 12, parentID: 5, count: 2)
        let allCategories = rootCategories + subCategories1

        // Then
        let viewModels = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: allCategories, selectedCategories: selectedCategories)

        // When
        let selectedCategoryNames = selectedCategories.map { $0.name }
        let selectedViewModelsNames = viewModels.filter { $0.isSelected }.map { $0.name }
        XCTAssertEqual(selectedCategoryNames, selectedViewModelsNames)
    }
}

// MARK: Helpers
//
private extension ProductCategoryViewModelBuilderTests {
    func sampleCategories(initialID: Int64, parentID: Int64 = 0, count: Int64) -> [ProductCategory] {
        return (initialID..<initialID + count).map {
            return sampleCategory(parentID: parentID, categoryID: $0)
        }
    }

    func sampleCategory(parentID: Int64 = 0, categoryID: Int64) -> ProductCategory {
        return ProductCategory(categoryID: categoryID, siteID: sampleSiteID, parentID: parentID, name: "\(categoryID)", slug: "")
    }
}
