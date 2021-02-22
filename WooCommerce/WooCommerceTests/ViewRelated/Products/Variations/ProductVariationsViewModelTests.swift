import XCTest
@testable import WooCommerce
import Yosemite

final class ProductVariationsViewModelTests: XCTestCase {
    func test_more_button_appears_when_product_is_not_empty_and_addProductVariations_feature_is_enabled() {
        // Arrange
        let variations: [Int64] = [101, 102]
        let product = Product().copy(variations: variations)
        let viewModel = ProductVariationsViewModel(product: product, isAddProductVariationsEnabled: true)

        // Assert
        XCTAssertEqual(viewModel.showMoreButton, true)
    }

    func test_more_button_does_not_appear_when_product_is_not_empty_and_addProductVariations_feature_is_disabled() {
        // Arrange
        let variations: [Int64] = [101, 102]
        let product = Product().copy(variations: variations)
        let viewModel = ProductVariationsViewModel(product: product, isAddProductVariationsEnabled: false)

        // Assert
        XCTAssertEqual(viewModel.showMoreButton, false)
    }

    func test_more_button_does_not_appear_when_product_is_empty_and_addProductVariations_feature_is_enabled() {
        // Arrange
        let product = Product().copy()
        let viewModel = ProductVariationsViewModel(product: product, isAddProductVariationsEnabled: true)

        // Assert
        XCTAssertEqual(viewModel.showMoreButton, false)
    }

    func test_more_button_does_not_appear_when_product_is_empty_and_addProductVariations_feature_is_disabled() {
        // Arrange
        let product = Product().copy()
        let viewModel = ProductVariationsViewModel(product: product, isAddProductVariationsEnabled: false)

        // Assert
        XCTAssertEqual(viewModel.showMoreButton, false)
    }
}
