import Combine
import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductInventorySettingsViewModelTests: XCTestCase {
    typealias Section = ProductInventorySettingsViewController.Section

    private var cancellable: AnyCancellable?

    override func tearDown() {
        cancellable = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func testReadonlyValuesAreAsExpectedAfterInitializingAProductWithManageStockEnabled() {
        // Arrange
        let sku = "134"
        let globalUniqueID = "12345"
        let product = Product.fake()
            .copy(sku: sku,
                  globalUniqueID: globalUniqueID,
                  manageStock: true,
                  stockQuantity: 12,
                  backordersKey: ProductBackordersSetting.allowed.rawValue,
                  soldIndividually: true)
        let model = EditableProductModel(product: product)

        // Act
        let featureFlagService = MockFeatureFlagService(isProductGlobalUniqueIdentifierSupported: true)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, featureFlagService: featureFlagService)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.globalUniqueIdentifier]),
            .init(rows: [.manageStock, .stockQuantity, .backorders]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(sections, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
        XCTAssertEqual(viewModel.globalUniqueID, globalUniqueID)
        XCTAssertTrue(viewModel.manageStockEnabled)
        XCTAssertEqual(viewModel.soldIndividually, true)
        XCTAssertEqual(viewModel.stockQuantity, 12)
        XCTAssertEqual(viewModel.backordersSetting, .allowed)
        XCTAssertTrue(viewModel.isStockStatusEnabled)
    }

    func testReadonlyValuesAreAsExpectedAfterInitializingAProductWithManageStockDisabled() {
        // Arrange
        let sku = "134"
        let globalUniqueID = "12345"
        let product = Product.fake()
            .copy(sku: sku, globalUniqueID: globalUniqueID, manageStock: false, stockStatusKey: ProductStockStatus.onBackOrder.rawValue, soldIndividually: true)
        let model = EditableProductModel(product: product)

        // Act
        let featureFlagService = MockFeatureFlagService(isProductGlobalUniqueIdentifierSupported: true)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, featureFlagService: featureFlagService)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.globalUniqueIdentifier]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(sections, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
        XCTAssertEqual(viewModel.globalUniqueID, globalUniqueID)
        XCTAssertFalse(viewModel.manageStockEnabled)
        XCTAssertEqual(viewModel.soldIndividually, true)
        XCTAssertEqual(viewModel.stockStatus, .onBackOrder)
        XCTAssertTrue(viewModel.isStockStatusEnabled)
    }

    func test_a_variable_product_with_manage_stock_disabled_has_no_stock_status_row() {
        // Arrange
        let product = Product.fake().copy(productTypeKey: ProductType.variable.rawValue, sku: "134")
        let model = EditableProductModel(product: product)

        // Act
        let featureFlagService = MockFeatureFlagService(isProductGlobalUniqueIdentifierSupported: true)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, featureFlagService: featureFlagService)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.globalUniqueIdentifier]),
            .init(rows: [.manageStock]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(sections, expectedSections)
    }

    func testOnlySKUAndGlobalUniqueIdentifierSectionsAreVisibleForSKUFormType() {
        // Arrange
        let product = Product.fake().copy(sku: "134", globalUniqueID: "12345")
        let model = EditableProductModel(product: product)

        // Act
        let featureFlagService = MockFeatureFlagService(isProductGlobalUniqueIdentifierSupported: true)
        let viewModel = ProductInventorySettingsViewModel(formType: .sku, productModel: model, featureFlagService: featureFlagService)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.globalUniqueIdentifier])
        ]
        XCTAssertEqual(sections, expectedSections)
        XCTAssertEqual(viewModel.sku, "134")
        XCTAssertEqual(viewModel.globalUniqueID, "12345")
    }

    // MARK: - `handleSKUChange`

    func testHandlingADuplicateSKUUpdatesTheSKUSectionWithError() {
        // Arrange
        let sku = "134"
        let product = Product.fake().copy(sku: "", manageStock: false)
        let model = EditableProductModel(product: product)
        let stores = MockProductSKUValidationStoresManager(existingSKUs: [sku])
        let featureFlagService = MockFeatureFlagService(isProductGlobalUniqueIdentifierSupported: true)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, stores: stores, featureFlagService: featureFlagService)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

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
        let expectedSections: [Section] = [
            .init(errorTitle: ProductUpdateError.duplicatedSKU.errorDescription, rows: [.sku]),
            .init(rows: [.globalUniqueIdentifier]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(sections, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
    }

    func testHandlingTheOriginalSKUIsAlwaysValid() {
        // Arrange
        let sku = "134"
        let product = Product.fake().copy(sku: sku, manageStock: false)
        let model = EditableProductModel(product: product)
        let stores = MockProductSKUValidationStoresManager(existingSKUs: [sku])
        let featureFlagService = MockFeatureFlagService(isProductGlobalUniqueIdentifierSupported: true)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, stores: stores, featureFlagService: featureFlagService)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

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
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.globalUniqueIdentifier]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(sections, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
    }

    // MARK: - `handleGlobalUniqueIdentifierChange`

    func testGlobalUniqueIdentifierWithLettersIsNotValid() {
        // Arrange
        let product = Product.fake().copy(globalUniqueID: "321")
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        var globalUniqueIdentifierIsValid: Bool?
        viewModel.handleGlobalUniqueIdentifierChange("1234test", onValidation: { isValid, _ in
            globalUniqueIdentifierIsValid = isValid
        })

        // Assert
        XCTAssertFalse(globalUniqueIdentifierIsValid ?? true)
    }

    func testGlobalUniqueIdentifierWithCharactersOtherThanHyphensIsNotValid() {
        // Arrange
        let product = Product.fake().copy(globalUniqueID: "321")
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

        // Act
        var globalUniqueIdentifierIsValid: Bool?
        viewModel.handleGlobalUniqueIdentifierChange("1234,", onValidation: { isValid, _ in
            globalUniqueIdentifierIsValid = isValid
        })

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(errorTitle: ProductUpdateError.invalidGlobalUniqueIdentifier.errorDescription, rows: [.globalUniqueIdentifier]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(sections, expectedSections)
        XCTAssertFalse(globalUniqueIdentifierIsValid ?? true)
    }

    func testGlobalUniqueIdentifierWithNumbersAndHyphensIsValid() {
        // Arrange
        let product = Product.fake().copy(globalUniqueID: "321")
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        var globalUniqueIdentifierIsValid: Bool?
        viewModel.handleGlobalUniqueIdentifierChange("123-456-789", onValidation: { isValid, _ in
            globalUniqueIdentifierIsValid = isValid
        })

        // Assert
        XCTAssertTrue(globalUniqueIdentifierIsValid ?? false)
    }

    func testEmptyGlobalUniqueIdentifierIsValid() {
        // Arrange
        let product = Product.fake().copy(globalUniqueID: "321")
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        var globalUniqueIdentifierIsValid: Bool?
        viewModel.handleGlobalUniqueIdentifierChange("", onValidation: { isValid, _ in
            globalUniqueIdentifierIsValid = isValid
        })

        // Assert
        XCTAssertTrue(globalUniqueIdentifierIsValid ?? false)
    }

    // MARK: - `handleManageStockEnabledChange`

    func testDisablingStockManagementUpdatesItsSections() {
        // Arrange
        let sku = "134"
        let product = Product.fake()
            .copy(sku: sku, manageStock: true, stockQuantity: 12, backordersKey: ProductBackordersSetting.allowed.rawValue, soldIndividually: true)
        let model = EditableProductModel(product: product)
        let featureFlagService = MockFeatureFlagService(isProductGlobalUniqueIdentifierSupported: true)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, featureFlagService: featureFlagService)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

        // Act
        viewModel.handleManageStockEnabledChange(false)

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.globalUniqueIdentifier]),
            .init(rows: [.manageStock, .stockStatus]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(sections, expectedSections)
    }

    func testEnablingStockManagementUpdatesItsSections() {
        // Arrange
        let sku = "134"
        let product = Product.fake()
            .copy(sku: sku, manageStock: false, stockStatusKey: ProductStockStatus.onBackOrder.rawValue, soldIndividually: true)
        let model = EditableProductModel(product: product)
        let featureFlagService = MockFeatureFlagService(isProductGlobalUniqueIdentifierSupported: true)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model, featureFlagService: featureFlagService)
        var sections: [Section] = []
        cancellable = viewModel.sections.sink { sectionsValue in
            sections = sectionsValue
        }

        // Act
        viewModel.handleManageStockEnabledChange(true)

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.globalUniqueIdentifier]),
            .init(rows: [.manageStock, .stockQuantity, .backorders]),
            .init(rows: [.limitOnePerOrder])
        ]
        XCTAssertEqual(sections, expectedSections)
    }

    // MARK: - `hasUnsavedChanges`

    func testViewModelHasUnsavedChangesAfterUpdatingSoldInvidually() {
        // Arrange
        let product = Product.fake().copy(soldIndividually: true)
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        viewModel.handleSoldIndividuallyChange(false)

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testViewModelHasUnsavedChangesAfterUpdatingGlobalUniqueId() {
        // Arrange
        let product = Product.fake().copy(globalUniqueID: "321")
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        viewModel.handleGlobalUniqueIdentifierChange("123", onValidation: { _, _ in })

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testViewModelHasUnsavedChangesAfterScanningANewGlobalUniqueId() {
        // Arrange
        let product = Product.fake().copy(globalUniqueID: "321")
        let model = EditableProductModel(product: product)
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)

        // Act
        viewModel.handleGlobalUniqueIdentifierFromBarcodeScanner("123", onValidation: { _, _ in })

        // Assert
        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

    func testViewModelHasNoUnsavedChangesAfterUpdatingWithTheOriginalValues() {
        // Arrange
        let product = Product.fake()
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
