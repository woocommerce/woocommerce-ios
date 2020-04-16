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

        let rootViewModels = viewModels.filter { rootCategoriesNames.contains($0.name) }
        XCTAssertEqual(rootViewModels.count, rootCategories.count)
        rootViewModels.forEach {
            XCTAssertEqual($0.indentationLevel, 0)
        }

        let subViewModels = viewModels.filter { subCategories1Names.contains($0.name) }
        XCTAssertEqual(subViewModels.count, subCategories1.count)
        subViewModels.forEach {
            XCTAssertEqual($0.indentationLevel, 1)
        }

        let subViewModels2 = viewModels.filter { subCategories2Names.contains($0.name) }
        XCTAssertEqual(subViewModels2.count, subCategories2.count)
        subViewModels2.forEach {
            XCTAssertEqual($0.indentationLevel, 2)
        }
    }

    func testRootCategoriesAreSelectedWhenProvidingProductSelectedCategories() {
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

    func testSubCategoriesAreSelectedWhenProvidingProductSelectedCategoriesWithSubCategories() {
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

    func testViewModelGenerationTimeWithFromBigSetOfCategories() {
        let rootCategories = sampleCategories(initialID: 1, count: 1000)
        let subCategories1 = sampleCategories(initialID: 1001, parentID: 5, count: 500)
        let subCategories2 = sampleCategories(initialID: 1601, parentID: 13, count: 300)
        let selectedCategories = sampleCategories(initialID: 1100, parentID: 5, count: 100)
        let allCategories = rootCategories + subCategories1 + subCategories2
        measure {
            _ = ProductCategoryListViewModel.CellViewModelBuilder.viewModels(from: allCategories, selectedCategories: selectedCategories)
        }
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
