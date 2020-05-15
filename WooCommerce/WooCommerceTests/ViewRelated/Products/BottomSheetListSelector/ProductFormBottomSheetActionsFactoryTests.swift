import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormBottomSheetActionsFactoryTests: XCTestCase {

    // M3 feature flag off & M2 feature flag is on

    func testDataHasNoEditProductsRelease3ActionsForAPhysicalProductWhenFeatureFlagIsOff() {
        let product = Fixtures.physicalProduct
        let isEditProductsRelease2Enabled = true
        let isEditProductsRelease3Enabled = false
        let actions = ProductFormBottomSheetActionsFactory.actions(product: product,
                                                                   isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                   isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editShippingSettings,
            .editBriefDescription
        ]
        XCTAssertEqual(actions, expectedActions)
    }

    func testDataHasNoEditProductsRelease3AndShippingActionsForAVirtualProductWhenFeatureFlagIsOff() {
        let product = Fixtures.virtualProduct
        let isEditProductsRelease2Enabled = true
        let isEditProductsRelease3Enabled = false
        let actions = ProductFormBottomSheetActionsFactory.actions(product: product,
                                                                   isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                   isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editBriefDescription
        ]
        XCTAssertEqual(actions, expectedActions)
    }

    func testDataHasNoEditProductsRelease3AndShippingActionsForADownloadableProductWhenFeatureFlagIsOff() {
        let product = Fixtures.downloadableProduct
        let isEditProductsRelease2Enabled = true
        let isEditProductsRelease3Enabled = false
        let actions = ProductFormBottomSheetActionsFactory.actions(product: product,
                                                                   isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                   isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editBriefDescription
        ]
        XCTAssertEqual(actions, expectedActions)
    }

    // M3 feature flag on & M2 feature flag is on

    func testDataHasEditProductsRelease3ActionsForAPhysicalProductWhenFeatureFlagIsOn() {
        let product = Fixtures.physicalProduct
        let isEditProductsRelease2Enabled = true
        let isEditProductsRelease3Enabled = true
        let actions = ProductFormBottomSheetActionsFactory.actions(product: product,
                                                                   isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                   isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editShippingSettings,
            .editCategories,
            .editBriefDescription
        ]
        XCTAssertEqual(actions, expectedActions)
    }

    func testDataHasEditProductsRelease3ButNoShippingActionsForAVirtualProductWhenFeatureFlagIsOn() {
        let product = Fixtures.virtualProduct
        let isEditProductsRelease2Enabled = true
        let isEditProductsRelease3Enabled = true
        let actions = ProductFormBottomSheetActionsFactory.actions(product: product,
                                                                   isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                   isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editCategories,
            .editBriefDescription
        ]
        XCTAssertEqual(actions, expectedActions)
    }

    func testDataHasEditProductsRelease3ButNoShippingActionsForADownloadableProductWhenFeatureFlagIsOn() {
        let product = Fixtures.downloadableProduct
        let isEditProductsRelease2Enabled = true
        let isEditProductsRelease3Enabled = true
        let actions = ProductFormBottomSheetActionsFactory.actions(product: product,
                                                                   isEditProductsRelease2Enabled: isEditProductsRelease2Enabled,
                                                                   isEditProductsRelease3Enabled: isEditProductsRelease3Enabled)

        let expectedActions: [ProductFormBottomSheetAction] = [
            .editInventorySettings,
            .editCategories,
            .editBriefDescription
        ]
        XCTAssertEqual(actions, expectedActions)
    }

}

private extension ProductFormBottomSheetActionsFactoryTests {
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
