import XCTest
@testable import WooCommerce
import Yosemite

final class ProductVariationsViewModelTests: XCTestCase {
    func test_more_button_appears_when_product_is_not_empty() {
        // Given
        let variations: [Int64] = [101, 102]
        let attribute = ProductAttribute(siteID: 0, attributeID: 0, name: "attr", position: 0, visible: true, variation: true, options: [])
        let product = Product().copy(attributes: [attribute], variations: variations)
        let viewModel = ProductVariationsViewModel()

        // When
        let showMoreButton = viewModel.shouldShowMoreButton(for: product)

        // Then
        XCTAssertTrue(showMoreButton)
    }

    func test_more_button_does_not_appear_when_product_has_variations_does_not_have_attributes() {
        // Given
        let variations: [Int64] = [101, 102]
        let product = Product().copy(attributes: [], variations: variations)
        let viewModel = ProductVariationsViewModel()

        // When
        let showMoreButton = viewModel.shouldShowMoreButton(for: product)

        // Then
        XCTAssertFalse(showMoreButton)
    }

    func test_more_button_does_not_appear_when_product_is_empty() {
        // Given
        let product = Product().copy()
        let viewModel = ProductVariationsViewModel()

        // When
        let showMoreButton = viewModel.shouldShowMoreButton(for: product)

        // Then
        XCTAssertFalse(showMoreButton)
    }

    func test_empty_state_is_shown_when_product_does_not_have_variations_but_has_attributes() {
        // Given
        let attribute = ProductAttribute(siteID: 0, attributeID: 0, name: "attr", position: 0, visible: true, variation: true, options: [])
        let product = Product().copy(attributes: [attribute], variations: [])
        let viewModel = ProductVariationsViewModel()

        // Then
        let showEmptyState = viewModel.shouldShowEmptyState(for: product)

        // Then
        XCTAssertTrue(showEmptyState)
    }

    func test_empty_state_is_shown_when_product_does_not_have_attributes_but_has_variations() {
        // Given
        let product = Product().copy(attributes: [], variations: [1, 2])
        let viewModel = ProductVariationsViewModel()

        // Then
        let showEmptyState = viewModel.shouldShowEmptyState(for: product)

        // Then
        XCTAssertTrue(showEmptyState)
    }

    func test_empty_state_is_not_shown_when_product_has_attributes_and_variations() {
        // Given
        let attribute = ProductAttribute(siteID: 0, attributeID: 0, name: "attr", position: 0, visible: true, variation: true, options: [])
        let product = Product().copy(attributes: [attribute], variations: [1, 2])
        let viewModel = ProductVariationsViewModel()

        // Then
        let showEmptyState = viewModel.shouldShowEmptyState(for: product)

        // Then
        XCTAssertFalse(showEmptyState)
    }
}
