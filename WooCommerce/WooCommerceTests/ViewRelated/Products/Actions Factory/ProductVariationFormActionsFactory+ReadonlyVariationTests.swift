import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductVariationFormActionsFactory_ReadonlyVariationTests: XCTestCase {
    func test_variation_without_image_and_description_does_not_have_these_two_rows() {
        // Arrange
        let productVariation = Fixtures.variationWithoutImageAndDescription
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.variationName]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)
    }

    func test_variation_without_price_does_not_have_price_row_and_bottom_sheet_actions() {
        // Arrange
        let productVariation = Fixtures.variationWithoutPrice
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: false)

        // Assert
        XCTAssertFalse(factory.settingsSectionActions().contains(.priceSettings(editable: false)))

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_variation_actions_are_all_not_editable() {
        // Arrange
        let productVariation = Fixtures.variation
        let model = EditableProductVariationModel(productVariation: productVariation)

        // Action
        let factory = ProductVariationFormActionsFactory(productVariation: model, editable: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: false), .variationName, .description(editable: false)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: false),
                                                                       .attributes(editable: false),
                                                                       .status(editable: false),
                                                                       .shippingSettings(editable: false),
                                                                       .inventorySettings(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }
}

private extension ProductVariationFormActionsFactory_ReadonlyVariationTests {
    enum Fixtures {
        static let image = ProductImage(imageID: 19,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: "https://photo.jpg",
                                        name: "Tshirt",
                                        alt: "")
        // Variation without an image
        static let variationWithoutImageAndDescription = MockProductVariation().productVariation().copy(image: nil, description: "")
        // Variation without a price
        static let variationWithoutPrice = MockProductVariation().productVariation().copy(regularPrice: "", salePrice: "")
        // Variation with data so that all rows are shown
        static let variation = MockProductVariation().productVariation()
            .copy(image: image, description: "hello", regularPrice: "1", manageStock: false,
                  weight: "2", dimensions: ProductDimensions(length: "", width: "", height: ""))
    }
}
