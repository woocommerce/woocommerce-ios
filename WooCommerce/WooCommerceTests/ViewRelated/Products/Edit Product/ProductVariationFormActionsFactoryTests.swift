import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductVariationFormActionsFactoryTests: XCTestCase {
    func testActionsForAPhysicalProductVariationWithoutImages() {
        // Arrange
        let productVariation = Fixtures.physicalProductVariationWithoutImages
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings,
                                                                       .status,
                                                                       .shippingSettings,
                                                                       .inventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testActionsForAPhysicalProductVariationWithImages() {
        // Arrange
        let productVariation = Fixtures.physicalProductVariationWithImages
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings,
                                                                       .status,
                                                                       .shippingSettings,
                                                                       .inventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testActionsForAPhysicalProductVariationWithImagesMissingShippingData() {
        // Arrange
        let productVariation = Fixtures.physicalProductVariationWithImagesWithoutShipping
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings,
                                                                       .status,
                                                                       .inventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editShippingSettings]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testActionsForADownloadableProductVariation() {
        // Arrange
        let productVariation = Fixtures.downloadableProductVariation
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .status, .inventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testActionsForAVirtualProductVariation() {
        // Arrange
        let productVariation = Fixtures.virtualProductVariation
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .status, .inventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }
}

private extension ProductVariationFormActionsFactoryTests {
    enum Fixtures {
        static let image = ProductImage(imageID: 19,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: "https://photo.jpg",
                                        name: "Tshirt",
                                        alt: "")
        // downloadable: false, virtual: false, with inventory/shipping
        static let physicalProductVariationWithoutImages = MockProductVariation().productVariation()
            .copy(image: nil, sku: "uks", virtual: false, downloadable: false,
                  manageStock: true, stockQuantity: nil,
                  weight: "2", dimensions: ProductDimensions(length: "", width: "", height: ""))
        // downloadable: false, virtual: false, with inventory/shipping
        static let physicalProductVariationWithImages = MockProductVariation().productVariation()
            .copy(image: image, sku: "uks", virtual: false, downloadable: false,
                  manageStock: true, stockQuantity: nil,
                  weight: "2", dimensions: ProductDimensions(length: "", width: "", height: ""))
        // downloadable: false, virtual: false, with inventory and without shipping
        static let physicalProductVariationWithImagesWithoutShipping = MockProductVariation().productVariation()
            .copy(image: image, sku: "uks", virtual: false, downloadable: false,
                  manageStock: true, stockQuantity: nil)
        // downloadable: false, virtual: true, with inventory/shipping
        static let virtualProductVariation = MockProductVariation().productVariation()
            .copy(image: nil, sku: "uks", virtual: true, downloadable: false,
                  manageStock: true, stockQuantity: nil,
                  weight: "2", dimensions: ProductDimensions(length: "", width: "", height: ""))
        // downloadable: true, virtual: false, missing inventory/shipping
        static let downloadableProductVariation = MockProductVariation().productVariation()
            .copy(image: nil, sku: "uks", virtual: false, downloadable: true)
    }
}
