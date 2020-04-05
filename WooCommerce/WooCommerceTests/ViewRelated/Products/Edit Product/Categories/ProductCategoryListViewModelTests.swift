import XCTest

@testable import WooCommerce
@testable import Yosemite

/// Tests for `ProductCategoryListViewModel`.
///
final class ProductCategoryListViewModelTests: XCTestCase {

    func testsCategoriesAreSelectedIfTheyArePartOfMainProduct() {
        // Given
        let categories = (1...3).map { sampleCategory(categoryID: $0, name: String($0)) }
        let product = MockProduct().product(categories: categories)
        let viewModel = ProductCategoryListViewModel(product: product)

        // When
        for category in categories {
            let isCategorySelected = viewModel.isCategorySelected(category)

            // Then
            XCTAssertTrue(isCategorySelected)
        }
    }

    func testCategoryIsNotSelectedIfItsNotPartOfMainProduct() {
        // Given
        let category = sampleCategory(categoryID: 1, name: "1")
        let product = MockProduct().product(categories: [])
        let viewModel = ProductCategoryListViewModel(product: product)

        // When
        let isCategorySelected = viewModel.isCategorySelected(category)

        // Then
        XCTAssertFalse(isCategorySelected)
    }
}

private extension ProductCategoryListViewModelTests {
    func sampleCategory(categoryID: Int64, name: String) -> ProductCategory {
        return ProductCategory(categoryID: categoryID, siteID: 123, parentID:0, name: name, slug: "")
    }
}
