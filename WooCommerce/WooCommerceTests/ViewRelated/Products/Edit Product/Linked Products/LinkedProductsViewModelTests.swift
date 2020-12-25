import XCTest
@testable import WooCommerce
@testable import Yosemite

final class LinkedProductsViewModelTests: XCTestCase {

    // MARK: - Initialization

    func test_readonly_values_are_as_expected_after_initializing_linked_products() {
        // Arrange
        let product = MockProduct().product(upsellIDs: [1, 2], crossSellIDs: [3, 4])
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = LinkedProductsViewModel(product: model)

        // Assert
        XCTAssertEqual(viewModel.upsellIDs, [1, 2])
        XCTAssertEqual(viewModel.crossSellIDs, [3, 4])
    }

    func test_section_and_row_values_are_as_expected_after_initializing_linked_products_with_non_empty_data() {
        // Arrange
        let product = MockProduct().product(upsellIDs: [1, 2], crossSellIDs: [3, 4])
        let model = EditableProductModel(product: product)
        let viewModel = LinkedProductsViewModel(product: model)

        // Act
        let expectedSections: [LinkedProductsViewController.Section] = [
            LinkedProductsViewController.Section(rows: [.upsells, .upsellsProducts, .upsellsButton, .crossSells, .crossSellsProducts, .crossSellsButton])
        ]

        // Assert
        XCTAssertEqual(viewModel.sections, expectedSections)
    }

    func test_section_and_row_values_are_as_expected_after_initializing_linked_products_with_empty_data() {
        // Arrange
        let product = MockProduct().product(upsellIDs: [], crossSellIDs: [])
        let model = EditableProductModel(product: product)
        let viewModel = LinkedProductsViewModel(product: model)

        // Act
        let expectedSections: [LinkedProductsViewController.Section] = [
            LinkedProductsViewController.Section(rows: [.upsells, .upsellsButton, .crossSells, .crossSellsButton])
        ]

        // Assert
        XCTAssertEqual(viewModel.sections, expectedSections)
    }

    // MARK: - `handleUpsellIDsChange` & `handleCrossSellIDsChange`

    func test_handling_upsellIDs_updates_return_the_expected_values() throws {
        // Arrange
        let product = MockProduct().product(upsellIDs: [1, 2, 3])
        let model = EditableProductModel(product: product)
        let viewModel = LinkedProductsViewModel(product: model)

        // Act
        viewModel.handleUpsellIDsChange([2, 5])

        // Assert
        let expectedValue: [Int64] = [2, 5]
        XCTAssertEqual(viewModel.upsellIDs, expectedValue)
    }

    func test_handling_crossSellIDs_updates_return_the_expected_values() throws {
        // Arrange
        let product = MockProduct().product(crossSellIDs: [1, 2, 3])
        let model = EditableProductModel(product: product)
        let viewModel = LinkedProductsViewModel(product: model)

        // Act
        viewModel.handleCrossSellIDsChange([9, 10])

        // Assert
        let expectedValue: [Int64] = [9, 10]
        XCTAssertEqual(viewModel.crossSellIDs, expectedValue)
    }

    // MARK: - `hasUnsavedChanges`

    func test_viewModel_has_unsaved_changes_after_updating_upsellIDs() {
        // Arrange
        let product = MockProduct().product(upsellIDs: [1, 2, 5])
        let model = EditableProductModel(product: product)
        let viewModel = LinkedProductsViewModel(product: model)

        // Act
        viewModel.handleUpsellIDsChange([1])

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_has_unsaved_changes_after_updating_crossSellIDs() {
        // Arrange
        let product = MockProduct().product(crossSellIDs: [5, 7])
        let model = EditableProductModel(product: product)
        let viewModel = LinkedProductsViewModel(product: model)

        // Act
        viewModel.handleCrossSellIDsChange([5])

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func test_viewModel_doesnt_have_unsaved_changes_if_there_are_no_changes_to_data() {
        // Arrange
        let product = MockProduct().product(upsellIDs: [1, 2], crossSellIDs: [3, 4])
        let model = EditableProductModel(product: product)
        let viewModel = LinkedProductsViewModel(product: model)

        //Act
        viewModel.handleUpsellIDsChange([1, 2])
        viewModel.handleCrossSellIDsChange([3, 4])

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }
}
