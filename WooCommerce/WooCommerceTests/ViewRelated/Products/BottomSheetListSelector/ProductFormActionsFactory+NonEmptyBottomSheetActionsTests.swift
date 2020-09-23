import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactory_NonEmptyBottomSheetActionsTests: XCTestCase {

    // M3 feature flag off & M2 feature flag on

    func testDataHasNoEditProductsRelease3ActionsForAPhysicalProductWhenM3FeatureFlagIsOff() {
        // Arrange
        let product = Fixtures.physicalProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editShippingSettings, .editInventorySettings, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testDataHasNoEditProductsRelease3AndShippingActionsForAVirtualProductWhenM3FeatureFlagIsOff() {
        // Arrange
        let product = Fixtures.virtualProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editInventorySettings, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testDataHasNoEditProductsRelease3AndShippingActionsForADownloadableProductWhenM3FeatureFlagIsOff() {
        // Arrange
        let product = Fixtures.downloadableProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editInventorySettings, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    // M3 feature flag on & M2 feature flag is on

    func testDataHasEditProductsRelease3ActionsForAPhysicalProductWhenBothFeatureFlagsAreOn() {
        // Arrange
        let product = Fixtures.physicalProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .reviews, .productType]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editShippingSettings,
                                                                          .editInventorySettings,
                                                                          .editCategories,
                                                                          .editTags,
                                                                          .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testDataHasEditProductsRelease3ButNoShippingActionsForAVirtualProductWhenBothFeatureFlagsAreOn() {
        // Arrange
        let product = Fixtures.virtualProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .reviews, .productType]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editInventorySettings, .editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testDataHasEditProductsRelease3ButNoShippingActionsForADownloadableProductWhenBothFeatureFlagsAreOn() {
        // Arrange
        let product = Fixtures.downloadableProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .reviews, .productType]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editInventorySettings, .editCategories, .editTags, .editBriefDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

}

private extension ProductFormActionsFactory_NonEmptyBottomSheetActionsTests {
    enum Fixtures {
        // downloadable: false, virtual: false, missing inventory/shipping/categories/tags/brief description
        static let physicalProduct = MockProduct().product(downloadable: false, briefDescription: "", manageStock: true, sku: nil, stockQuantity: nil,
                                                           dimensions: ProductDimensions(length: "", width: "", height: ""), weight: nil,
                                                           virtual: false,
                                                           categories: [],
                                                           tags: [])
        // downloadable: false, virtual: true, missing inventory/shipping/categories/tags/brief description
        static let virtualProduct = MockProduct().product(downloadable: false, briefDescription: "", manageStock: true, sku: nil, stockQuantity: nil,
                                                          dimensions: ProductDimensions(length: "", width: "", height: ""), weight: nil,
                                                          virtual: true,
                                                          categories: [],
                                                          tags: [])
        // downloadable: true, virtual: true, missing inventory/shipping/categories/tags/brief description
        static let downloadableProduct = MockProduct().product(downloadable: true, briefDescription: "", manageStock: true, sku: nil, stockQuantity: nil,
                                                               dimensions: ProductDimensions(length: "", width: "", height: ""), weight: nil,
                                                               virtual: true,
                                                               categories: [],
                                                               tags: [])
    }
}
