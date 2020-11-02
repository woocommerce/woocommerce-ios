import XCTest
import Yosemite

@testable import WooCommerce

final class DefaultProductFormTableViewModelTests: XCTestCase {
    func test_simple_product_inventory_row_details_shows_stock_status_when_stock_management_is_disabled_without_sku() {
        // Arrange
        let product = MockProduct().product().copy(productTypeKey: ProductType.simple.rawValue,
                                                   sku: "",
                                                   manageStock: false,
                                                   stockStatusKey: ProductStockStatus.onBackOrder.rawValue)
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model,
                                                       formType: .edit,
                                                       isEditProductsRelease5Enabled: false)

        // Action
        let tableViewModel = DefaultProductFormTableViewModel(product: model, actionsFactory: actionsFactory, currency: "")

        // Assert
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var inventoryViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .inventory(viewModel, _) = row {
                inventoryViewModel = viewModel
                break
            }
        }
        XCTAssertEqual(inventoryViewModel?.details, ProductStockStatus.onBackOrder.description)
    }

    func test_variable_product_inventory_row_has_no_details_when_stock_management_is_disabled_without_sku() {
        // Arrange
        let product = MockProduct().product().copy(productTypeKey: ProductType.variable.rawValue,
                                                   sku: "",
                                                   manageStock: false,
                                                   stockStatusKey: ProductStockStatus.onBackOrder.rawValue)
        let model = EditableProductModel(product: product)
        let actionsFactory = ProductFormActionsFactory(product: model,
                                                       formType: .edit,
                                                       isEditProductsRelease5Enabled: false)

        // Action
        let tableViewModel = DefaultProductFormTableViewModel(product: model, actionsFactory: actionsFactory, currency: "")

        // Assert
        guard case let .settings(rows) = tableViewModel.sections[1] else {
            XCTFail("Unexpected section at index 1: \(tableViewModel.sections)")
            return
        }
        var inventoryViewModel: ProductFormSection.SettingsRow.ViewModel?
        for row in rows {
            if case let .inventory(viewModel, _) = row {
                inventoryViewModel = viewModel
                break
            }
        }
        XCTAssertNil(inventoryViewModel?.details)
    }
}
