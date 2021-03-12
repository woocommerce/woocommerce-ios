import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactory_NonEmptyBottomSheetActionsTests: XCTestCase {
    func testDataHasEditProductsRelease3ActionsForAPhysicalProductWhenBothFeatureFlagsAreOn() {
        // Arrange
        let product = Fixtures.physicalProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .reviews,
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editShippingSettings,
                                                                          .editInventorySettings,
                                                                          .editCategories,
                                                                          .editTags,
                                                                          .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testDataHasEditProductsRelease3ButNoShippingActionsForAVirtualProductWhenBothFeatureFlagsAreOn() {
        // Arrange
        let product = Fixtures.virtualProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .reviews,
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editInventorySettings, .editCategories, .editTags, .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testDataHasEditProductsRelease3ButNoShippingActionsForADownloadableProductWhenBothFeatureFlagsAreOn() {
        // Arrange
        let product = Fixtures.downloadableProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .edit)

        // Assert
        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .reviews,
                                                                       .downloadableFiles(editable: true),
                                                                       .linkedProducts(editable: true),
                                                                       .productType(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editInventorySettings, .editCategories, .editTags, .editShortDescription]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

}

private extension ProductFormActionsFactory_NonEmptyBottomSheetActionsTests {
    enum Fixtures {
        // downloadable: false, virtual: false, missing inventory/shipping/categories/tags/short description
        static let physicalProduct = Product.fake().copy(productTypeKey: ProductType.simple.rawValue,
                                                         virtual: false,
                                                         downloadable: false,
                                                         manageStock: true,
                                                         reviewsAllowed: true,
                                                         upsellIDs: [4, 5, 6],
                                                         crossSellIDs: [1, 2, 3])
        // downloadable: false, virtual: true, missing inventory/shipping/categories/tags/short description
        static let virtualProduct = Fixtures.physicalProduct.copy(virtual: true)
        // downloadable: true, virtual: true, missing inventory/shipping/categories/tags/short description
        static let downloadableProduct = Fixtures.physicalProduct.copy(virtual: true, downloadable: true)
    }
}
