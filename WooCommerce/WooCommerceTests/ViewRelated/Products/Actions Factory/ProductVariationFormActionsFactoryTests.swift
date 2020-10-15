import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductVariationFormActionsFactoryTests: XCTestCase {
    func test_actions_for_a_physical_ProductVariation_without_images() {
        // Arrange
        let productVariation = Fixtures.physicalProductVariationWithoutImages
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .variationName, .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .status(editable: true),
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_a_physical_ProductVariation_with_images() {
        // Arrange
        let productVariation = Fixtures.physicalProductVariationWithImages
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .variationName, .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .status(editable: true),
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_a_physical_ProductVariation_without_images_missing_shipping_data() {
        // Arrange
        let productVariation = Fixtures.physicalProductVariationWithImagesWithoutShipping
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .variationName, .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .status(editable: true),
                                                                       .inventorySettings(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = [.editShippingSettings]
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_a_downloadable_ProductVariation() {
        // Arrange
        let productVariation = Fixtures.downloadableProductVariation
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .variationName, .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .status(editable: true),
                                                                       .inventorySettings(editable: true)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_actions_for_a_virtual_ProductVariation() {
        // Arrange
        let productVariation = Fixtures.virtualProductVariation
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .variationName, .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [
            .priceSettings(editable: true),
            .status(editable: true),
            .inventorySettings(editable: true)
        ]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_a_ProductVariation_enabled_but_no_price_has_no_price_warning_row() {
        // Arrange
        let productVariation = Fixtures.physicalProductVariationEnabledAndMissingPrice
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: true), .variationName, .description(editable: true)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: true),
                                                                       .noPriceWarning, .status(editable: true),
                                                                       .shippingSettings(editable: true),
                                                                       .inventorySettings(editable: true)]
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
            .copy(image: nil, sku: "uks", regularPrice: "1", virtual: false, downloadable: false,
                  manageStock: true, stockQuantity: nil,
                  weight: "2", dimensions: ProductDimensions(length: "", width: "", height: ""))
        // downloadable: false, virtual: false, with inventory/shipping
        static let physicalProductVariationWithImages = MockProductVariation().productVariation()
            .copy(image: image, sku: "uks", regularPrice: "1", virtual: false, downloadable: false,
                  manageStock: true, stockQuantity: nil,
                  weight: "2", dimensions: ProductDimensions(length: "", width: "", height: ""))
        // downloadable: false, virtual: false, with inventory and without shipping
        static let physicalProductVariationWithImagesWithoutShipping = MockProductVariation().productVariation()
            .copy(image: image, sku: "uks", regularPrice: "1", virtual: false, downloadable: false,
                  manageStock: true, stockQuantity: nil)
        // downloadable: false, virtual: true, with inventory/shipping
        static let virtualProductVariation = MockProductVariation().productVariation()
            .copy(image: nil, sku: "uks", regularPrice: "1", virtual: true, downloadable: false,
                  manageStock: true, stockQuantity: nil,
                  weight: "2", dimensions: ProductDimensions(length: "", width: "", height: ""))
        // downloadable: true, virtual: false, missing inventory/shipping
        static let downloadableProductVariation = MockProductVariation().productVariation()
            .copy(image: nil, sku: "uks", regularPrice: "1", virtual: false, downloadable: true)
        // downloadable: false, virtual: false, status is enabled and has no price
        static let physicalProductVariationEnabledAndMissingPrice = MockProductVariation().productVariation()
            .copy(image: nil, status: .publish, sku: "uks", regularPrice: nil, virtual: false, downloadable: false,
                  weight: "2", dimensions: ProductDimensions(length: "", width: "", height: ""))
    }
}
