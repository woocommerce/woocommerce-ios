import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductInventorySettingsViewModel_VariationTests: XCTestCase {
    typealias Section = ProductInventorySettingsViewController.Section

    private var cancellable: ObservationToken?

    override func tearDown() {
        cancellable = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func testReadonlyValuesAreAsExpectedAfterInitializingAProductVariationWithManageStockEnabled() {
        // Arrange
        let sku = "134"
        let productVariation = MockProductVariation().productVariation()
            .copy(sku: sku, manageStock: true, stockQuantity: 12, backordersKey: ProductBackordersSetting.allowed.rawValue)
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Act
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)
        var sections: [Section] = []
        cancellable = viewModel.sections.subscribe { sectionsValue in
            sections = sectionsValue
        }

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.manageStock, .stockQuantity, .backorders])
        ]
        XCTAssertEqual(sections, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
        XCTAssertTrue(viewModel.manageStockEnabled)
        XCTAssertEqual(viewModel.soldIndividually, nil)
        XCTAssertEqual(viewModel.stockQuantity, 12)
        XCTAssertEqual(viewModel.backordersSetting, .allowed)
        XCTAssertFalse(viewModel.isStockStatusEnabled)
    }

    func testReadonlyValuesAreAsExpectedAfterInitializingAProductVariationWithManageStockDisabled() {
        // Arrange
        let sku = "134"
        let productVariation = MockProductVariation().productVariation()
            .copy(sku: sku, manageStock: false, stockStatus: .onBackOrder)
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Act
        let viewModel = ProductInventorySettingsViewModel(formType: .inventory, productModel: model)
        var sections: [Section] = []
        cancellable = viewModel.sections.subscribe { sectionsValue in
            sections = sectionsValue
        }

        // Assert
        let expectedSections: [Section] = [
            .init(rows: [.sku]),
            .init(rows: [.manageStock, .stockStatus])
        ]
        XCTAssertEqual(sections, expectedSections)
        XCTAssertEqual(viewModel.sku, sku)
        XCTAssertFalse(viewModel.manageStockEnabled)
        XCTAssertEqual(viewModel.soldIndividually, nil)
        XCTAssertEqual(viewModel.stockStatus, .onBackOrder)
        XCTAssertFalse(viewModel.isStockStatusEnabled)
    }
}
