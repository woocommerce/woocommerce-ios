import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactory_ReadonlyProductTests: XCTestCase {
    func test_readonly_simple_product_without_images_and_description_does_not_have_these_two_rows() {
        // Arrange
        let product = Fixtures.simpleProductWithoutImagesAndDescription
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .readonly,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.name(editable: false)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)
    }

    func test_readonly_simple_product_form_actions_are_all_not_editable() {
        // Arrange
        let product = Fixtures.simpleProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .readonly,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: false), .name(editable: false), .description(editable: false)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: false),
                                                                       .reviews,
                                                                       .shippingSettings(editable: false),
                                                                       .inventorySettings(editable: false),
                                                                       .categories(editable: false),
                                                                       .tags(editable: false),
                                                                       .shortDescription(editable: false),
                                                                       .productType(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    // MARK: - Affiliate products

    func test_readonly_affiliate_product_form_actions_are_all_not_editable() {
        // Arrange
        let product = Fixtures.affiliateProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .readonly,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: false), .name(editable: false), .description(editable: false)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: false),
                                                                       .reviews,
                                                                       .externalURL(editable: false),
                                                                       .sku(editable: false),
                                                                       .categories(editable: false),
                                                                       .tags(editable: false),
                                                                       .shortDescription(editable: false),
                                                                       .productType(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_readonly_affiliate_product_without_externalURL_and_sku_does_not_have_these_two_rows() {
        // Arrange
        let product = Fixtures.affiliateProductWithoutExternalURLAndSKU
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .readonly,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: false), .name(editable: false), .description(editable: false)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings(editable: false),
                                                                       .reviews,
                                                                       .categories(editable: false),
                                                                       .tags(editable: false),
                                                                       .shortDescription(editable: false),
                                                                       .productType(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    // MARK: - Grouped products

    func test_readonly_grouped_product_form_actions_are_all_not_editable() {
        // Arrange
        let product = Fixtures.groupedProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .readonly,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: false), .name(editable: false), .description(editable: false)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.groupedProducts(editable: false),
                                                                       .reviews,
                                                                       .sku(editable: false),
                                                                       .categories(editable: false),
                                                                       .tags(editable: false),
                                                                       .shortDescription(editable: false),
                                                                       .productType(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func test_readonly_grouped_product_without_sku_does_not_have_sku_row() {
        // Arrange
        let product = Fixtures.groupedProductWithoutSKU
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .readonly,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: false), .name(editable: false), .description(editable: false)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.groupedProducts(editable: false),
                                                                       .reviews,
                                                                       .categories(editable: false),
                                                                       .tags(editable: false),
                                                                       .shortDescription(editable: false),
                                                                       .productType(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    // MARK: - Variable products

    func test_readonly_variable_product_form_actions_are_all_not_editable() {
        // Arrange
        let product = Fixtures.variableProduct
        let model = EditableProductModel(product: product)

        // Action
        let factory = ProductFormActionsFactory(product: model,
                                                formType: .readonly,
                                                isEditProductsRelease5Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images(editable: false), .name(editable: false), .description(editable: false)]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.variations,
                                                                       .reviews,
                                                                       .shippingSettings(editable: false),
                                                                       .inventorySettings(editable: false),
                                                                       .categories(editable: false),
                                                                       .tags(editable: false),
                                                                       .shortDescription(editable: false),
                                                                       .productType(editable: false)]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormBottomSheetAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }
}

private extension ProductFormActionsFactory_ReadonlyProductTests {
    enum Fixtures {
        static let category = ProductCategory(categoryID: 1, siteID: 2, parentID: 6, name: "", slug: "")
        static let image = ProductImage(imageID: 19,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: "https://photo.jpg",
                                        name: "Tshirt",
                                        alt: "")
        static let tag = ProductTag(siteID: 123, tagID: 1, name: "", slug: "")
        // Simple product without an image and description
        static let simpleProductWithoutImagesAndDescription = MockProduct().product()
            .copy(productTypeKey: ProductType.simple.rawValue, fullDescription: "", images: [])
        // Simple product with data so that all rows are shown
        static let simpleProduct = MockProduct().product().copy(name: "Affiliate",
                                                                productTypeKey: ProductType.simple.rawValue,
                                                                fullDescription: "Woooooo0o",
                                                                shortDescription: "Woo",
                                                                sku: "woo",
                                                                price: "",
                                                                regularPrice: "12.6",
                                                                manageStock: false,
                                                                reviewsAllowed: true,
                                                                categories: [category],
                                                                tags: [tag],
                                                                images: [image])
        // Affiliate product with data so that all rows are shown
        static let affiliateProduct = MockProduct().product().copy(name: "Affiliate",
                                                                   productTypeKey: ProductType.affiliate.rawValue,
                                                                   fullDescription: "Woooooo0o",
                                                                   shortDescription: "Woo",
                                                                   sku: "woo",
                                                                   price: "",
                                                                   regularPrice: "12.6",
                                                                   externalURL: "woo.com",
                                                                   reviewsAllowed: true,
                                                                   categories: [category],
                                                                   tags: [tag],
                                                                   images: [image])
        // Affiliate product without external URL and SKU
        static let affiliateProductWithoutExternalURLAndSKU = affiliateProduct.copy(sku: "",
                                                                                    externalURL: "")
        // Grouped product with data so that all rows are shown
        static let groupedProduct = MockProduct().product().copy(name: "Grouped",
                                                                 productTypeKey: ProductType.grouped.rawValue,
                                                                 fullDescription: "Woooooo0o",
                                                                 shortDescription: "Woo",
                                                                 sku: "woo",
                                                                 price: "",
                                                                 regularPrice: "12.6",
                                                                 reviewsAllowed: true,
                                                                 categories: [category],
                                                                 tags: [tag],
                                                                 images: [image],
                                                                 groupedProducts: [12])
        // Grouped product without a SKU
        static let groupedProductWithoutSKU = groupedProduct.copy(sku: "")
        // Variable product with data so that all rows are shown
        static let variableProduct = MockProduct().product().copy(name: "Grouped",
                                                                  productTypeKey: ProductType.variable.rawValue,
                                                                  fullDescription: "Woooooo0o",
                                                                  shortDescription: "Woo",
                                                                  price: "",
                                                                  regularPrice: "12.6",
                                                                  reviewsAllowed: true,
                                                                  categories: [category],
                                                                  tags: [tag],
                                                                  images: [image],
                                                                  variations: [12])
    }
}
