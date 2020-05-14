import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormBottomSheetListSelectorCommandTests: XCTestCase {
    // MARK: - `data`

    // M3 feature flag off

    func testDataHasNoEditProductsRelease3ActionsForAPhysicalProductWhenFeatureFlagIsOff() {
        let product = Fixtures.physicalProduct
        let isEditProductsRelease3Enabled = false
        let command = ProductFormBottomSheetListSelectorCommand(product: product,
                                                                isEditProductsRelease3Enabled: isEditProductsRelease3Enabled) { _ in }

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editShippingSettings,
            .editBriefDescription
        ]
        XCTAssertEqual(command.data, expectedActions)
    }

    func testDataHasNoEditProductsRelease3AndShippingActionsForAVirtualProductWhenFeatureFlagIsOff() {
        let product = Fixtures.virtualProduct
        let isEditProductsRelease3Enabled = false
        let command = ProductFormBottomSheetListSelectorCommand(product: product,
                                                                isEditProductsRelease3Enabled: isEditProductsRelease3Enabled) { _ in }

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editBriefDescription
        ]
        XCTAssertEqual(command.data, expectedActions)
    }

    func testDataHasNoEditProductsRelease3AndShippingActionsForADownloadableProductWhenFeatureFlagIsOff() {
        let product = Fixtures.downloadableProduct
        let isEditProductsRelease3Enabled = false
        let command = ProductFormBottomSheetListSelectorCommand(product: product,
                                                                isEditProductsRelease3Enabled: isEditProductsRelease3Enabled) { _ in }

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editBriefDescription
        ]
        XCTAssertEqual(command.data, expectedActions)
    }

    // M3 feature flag on

    func testDataHasEditProductsRelease3ActionsForAPhysicalProductWhenFeatureFlagIsOn() {
        let product = Fixtures.physicalProduct
        let isEditProductsRelease3Enabled = true
        let command = ProductFormBottomSheetListSelectorCommand(product: product,
                                                                isEditProductsRelease3Enabled: isEditProductsRelease3Enabled) { _ in }

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editShippingSettings,
            .editCategories,
            .editBriefDescription
        ]
        XCTAssertEqual(command.data, expectedActions)
    }

    func testDataHasEditProductsRelease3ButNoShippingActionsForAVirtualProductWhenFeatureFlagIsOn() {
        let product = Fixtures.virtualProduct
        let isEditProductsRelease3Enabled = true
        let command = ProductFormBottomSheetListSelectorCommand(product: product,
                                                                isEditProductsRelease3Enabled: isEditProductsRelease3Enabled) { _ in }

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editCategories,
            .editBriefDescription
        ]
        XCTAssertEqual(command.data, expectedActions)
    }

    func testDataHasEditProductsRelease3ButNoShippingActionsForADownloadableProductWhenFeatureFlagIsOn() {
        let product = Fixtures.downloadableProduct
        let isEditProductsRelease3Enabled = true
        let command = ProductFormBottomSheetListSelectorCommand(product: product,
                                                                isEditProductsRelease3Enabled: isEditProductsRelease3Enabled) { _ in }

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editCategories,
            .editBriefDescription
        ]
        XCTAssertEqual(command.data, expectedActions)
    }

    // MARK: - `handleSelectedChange`

    func testCallbackIsCalledOnSelection() {
        // Arrange
        let product = Fixtures.physicalProduct
        var selectedActions = [ProductFormBottomSheetAction]()
        let command = ProductFormBottomSheetListSelectorCommand(product: product,
                                                                isEditProductsRelease3Enabled: true) { selected in
                                                                    selectedActions.append(selected)
        }

        // Action
        command.handleSelectedChange(selected: .editInventorySettings)
        command.handleSelectedChange(selected: .editBriefDescription)
        command.handleSelectedChange(selected: .editShippingSettings)
        command.handleSelectedChange(selected: .editCategories)

        // Assert
        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editBriefDescription,
            .editShippingSettings,
            .editCategories
        ]
        XCTAssertEqual(selectedActions, expectedActions)
    }
}

private extension ProductFormBottomSheetListSelectorCommandTests {
    enum Fixtures {
        // downloadable: false, virtual: false, missing inventory/shipping/categories/brief description
        static let physicalProduct = MockProduct().product(downloadable: false, briefDescription: "", manageStock: true, sku: nil, stockQuantity: nil,
                                                           dimensions: ProductDimensions(length: "", width: "", height: ""), weight: nil,
                                                           virtual: false,
                                                           categories: [])
        // downloadable: false, virtual: true, missing inventory/shipping/categories/brief description
        static let virtualProduct = MockProduct().product(downloadable: false, briefDescription: "", manageStock: true, sku: nil, stockQuantity: nil,
                                                          dimensions: ProductDimensions(length: "", width: "", height: ""), weight: nil,
                                                          virtual: true,
                                                          categories: [])
        // downloadable: true, virtual: true, missing inventory/shipping/categories/brief description
        static let downloadableProduct = MockProduct().product(downloadable: true, briefDescription: "", manageStock: true, sku: nil, stockQuantity: nil,
                                                               dimensions: ProductDimensions(length: "", width: "", height: ""), weight: nil,
                                                               virtual: true,
                                                               categories: [])
    }
}
