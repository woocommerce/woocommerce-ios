import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductInventorySettingsViewModelTests: XCTestCase {
    // MARK: - Initialization

    func testReadonlyValuesAreAsExpectedAfterInitializingAProductWithManageStockEnabled() {
        // Arrange
        let sku = "134"
        let product = MockProduct().product()
            .copy(sku: sku, manageStock: true, stockQuantity: 12, backordersKey: ProductBackordersSetting.allowed.rawValue, soldIndividually: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Assert
        let expectedSections: [ProductInventorySettingsViewController.Section] = [
            .init(rows: [.sku]),
            .init(rows: [.manageStock, .stockQuantity, .backorders]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(viewModel.sectionsValue, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
        XCTAssertTrue(viewModel.manageStockEnabled)
        XCTAssertEqual(viewModel.soldIndividually, true)
        XCTAssertEqual(viewModel.stockQuantity, 12)
        XCTAssertEqual(viewModel.backordersSetting, .allowed)
        XCTAssertTrue(viewModel.isStockStatusEnabled)
    }

    func testReadonlyValuesAreAsExpectedAfterInitializingAProductWithManageStockDisabled() {
        // Arrange
        let sku = "134"
        let product = MockProduct().product()
            .copy(sku: sku, manageStock: false, stockStatusKey: ProductStockStatus.onBackOrder.rawValue, soldIndividually: true)
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Assert
        let expectedSections: [ProductInventorySettingsViewController.Section] = [
            .init(rows: [.sku]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(viewModel.sectionsValue, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
        XCTAssertFalse(viewModel.manageStockEnabled)
        XCTAssertEqual(viewModel.soldIndividually, true)
        XCTAssertEqual(viewModel.stockStatus, .onBackOrder)
        XCTAssertTrue(viewModel.isStockStatusEnabled)
    }

    func testOnlySKUSectionIsVisibleForSKUFormType() {
        // Arrange
        let product = MockProduct().product().copy(sku: "134")
        let model = EditableProductModel(product: product)

        // Act
        let viewModel = ProductInventorySettingsViewModel(formType: .sku, productModel: model)

        // Assert
        let expectedSections: [ProductInventorySettingsViewController.Section] = [
            .init(rows: [.sku])
        ]
        XCTAssertEqual(viewModel.sectionsValue, expectedSections)
        XCTAssertEqual(viewModel.sku, "134")
    }

    // MARK: - `handleSKUChange`

    func testHandlingADuplicateSKUUpdatesTheSKUSectionWithError() {
        // Arrange
        let sku = "134"
        let product = MockProduct().product().copy(sku: "", manageStock: false)
        let model = EditableProductModel(product: product)
        let stores = MockProductSKUValidationStoresManager(existingSKUs: [sku])
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, stores: stores)

        // Act
        var isSKUValid: Bool?
        var shouldBringUpKeyboard: Bool?
        waitForExpectation { exp in
            viewModel.handleSKUChange(sku) { (isValid, shouldBringUpKeyboardValue) in
                isSKUValid = isValid
                shouldBringUpKeyboard = shouldBringUpKeyboardValue
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isSKUValid, false)
        XCTAssertEqual(shouldBringUpKeyboard, true)
        let expectedSections: [ProductInventorySettingsViewController.Section] = [
            .init(errorTitle: ProductUpdateError.duplicatedSKU.alertMessage, rows: [.sku]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(viewModel.sectionsValue, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
    }

    func testHandlingTheOriginalSKUIsAlwaysValid() {
        // Arrange
        let sku = "134"
        let product = MockProduct().product().copy(sku: sku, manageStock: false)
        let model = EditableProductModel(product: product)
        let stores = MockProductSKUValidationStoresManager(existingSKUs: [sku])
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, stores: stores)

        // Act
        var isSKUValid: Bool?
        var shouldBringUpKeyboard: Bool?
        waitForExpectation { exp in
            viewModel.handleSKUChange(sku) { (isValid, shouldBringUpKeyboardValue) in
                isSKUValid = isValid
                shouldBringUpKeyboard = shouldBringUpKeyboardValue
                exp.fulfill()
            }
        }

        // Assert
        XCTAssertEqual(isSKUValid, true)
        XCTAssertEqual(shouldBringUpKeyboard, true)
        let expectedSections: [ProductInventorySettingsViewController.Section] = [
            .init(rows: [.sku]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(viewModel.sectionsValue, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
    }

    // MARK: - `handleManageStockEnabledChange`

    func testDisablingStockManagementUpdatesItsSections() {
        // Arrange
        let sku = "134"
        let product = MockProduct().product()
            .copy(sku: sku, manageStock: true, stockQuantity: 12, backordersKey: ProductBackordersSetting.allowed.rawValue, soldIndividually: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        viewModel.handleManageStockEnabledChange(false)

        // Assert
        let expectedSections: [ProductInventorySettingsViewController.Section] = [
            .init(rows: [.sku]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(viewModel.sectionsValue, expectedSections)
    }

    func testEnablingStockManagementUpdatesItsSections() {
        // Arrange
        let sku = "134"
        let product = MockProduct().product()
            .copy(sku: sku, manageStock: false, stockStatusKey: ProductStockStatus.onBackOrder.rawValue, soldIndividually: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        viewModel.handleManageStockEnabledChange(true)

        // Assert
        let expectedSections: [ProductInventorySettingsViewController.Section] = [
            .init(rows: [.sku]),
            .init(rows: [.manageStock, .stockQuantity, .backorders]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(viewModel.sectionsValue, expectedSections)
    }

    // MARK: - `hasUnsavedChanges`

    func testViewModelHasUnsavedChangesAfterUpdatingSoldInvidually() {
        // Arrange
        let product = MockProduct().product().copy(soldIndividually: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        viewModel.handleSoldIndividuallyChange(false)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testViewModelHasNoUnsavedChangesAfterUpdatingWithTheOriginalValues() {
        // Arrange
        let product = MockProduct().product()
            .copy(sku: "sku", manageStock: true, stockQuantity: 12, backordersKey: ProductBackordersSetting.allowed.rawValue, soldIndividually: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        viewModel.handleSKUChange(product.sku, onValidation: { _, _ in })
        viewModel.handleManageStockEnabledChange(product.manageStock)
        viewModel.handleSoldIndividuallyChange(product.soldIndividually)
        viewModel.handleStockQuantityChange("12")
        viewModel.handleBackordersSettingChange(product.backordersSetting)
        viewModel.handleStockStatusChange(product.productStockStatus)

        // Assert
        XCTAssertFalse(viewModel.hasUnsavedChanges())
    }
}
