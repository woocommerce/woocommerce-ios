import XCTest

@testable import WooCommerce
@testable import Yosemite

/// The same tests as `ProductFormActionsFactory_EditProductsM2Tests`, but with Edit Products M2 and M3 feature flag on.
/// When we fully launch Edit Products M2 and M3, we can replace `ProductFormActionsFactoryTests` with the test cases here.
///
final class ProductFormActionsFactory_EditProductsM3Tests: XCTestCase {
    func testViewModelForPhysicalSimpleProductWithoutImages() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithoutImages

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormAction] = [.editImages, .editName, .editDescription]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormAction] = [.editPriceSettings, .editShippingSettings, .editInventorySettings, .editCategories, .editBriefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForPhysicalSimpleProductWithImages() {
        // Arrange
        let product = Fixtures.physicalSimpleProductWithImages

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormAction] = [.editImages, .editName, .editDescription]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormAction] = [.editPriceSettings, .editShippingSettings, .editInventorySettings, .editCategories, .editBriefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForDownloadableSimpleProduct() {
        // Arrange
        let product = Fixtures.downloadableSimpleProduct

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormAction] = [.editImages, .editName, .editDescription]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormAction] = [.editPriceSettings, .editInventorySettings, .editCategories, .editBriefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVirtualSimpleProduct() {
        // Arrange
        let product = Fixtures.virtualSimpleProduct

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: true)

        // Assert
        let expectedPrimarySectionActions: [ProductFormAction] = [.editImages, .editName, .editDescription]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormAction] = [.editPriceSettings, .editInventorySettings, .editCategories, .editBriefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }
}

private extension ProductFormActionsFactory_EditProductsM3Tests {
    enum Fixtures {
        static let category = ProductCategory(categoryID: 1, siteID: 2, parentID: 6, name: "", slug: "")
        static let image = ProductImage(imageID: 19,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: "https://photo.jpg",
                                        name: "Tshirt",
                                        alt: "")
        // downloadable: false, virtual: false, with inventory/shipping/categories/brief description
        static let physicalSimpleProductWithoutImages = MockProduct().product(downloadable: false, briefDescription: "desc", productType: .simple,
                                                                              manageStock: true, sku: "uks", stockQuantity: nil,
                                                                              dimensions: ProductDimensions(length: "", width: "", height: ""), weight: "2",
                                                                              virtual: false,
                                                                              categories: [category], images: [])
        // downloadable: false, virtual: true, with inventory/shipping/categories/brief description
        static let physicalSimpleProductWithImages = MockProduct().product(downloadable: false, briefDescription: "desc", productType: .simple,
                                                                              manageStock: true, sku: "uks", stockQuantity: nil,
                                                                              dimensions: ProductDimensions(length: "", width: "", height: ""), weight: "2",
                                                                              virtual: false,
                                                                              categories: [category], images: [image])
        // downloadable: false, virtual: true, with inventory/shipping/categories/brief description
        static let virtualSimpleProduct = MockProduct().product(downloadable: false, briefDescription: "desc", productType: .simple,
                                                                manageStock: true, sku: "uks", stockQuantity: nil,
                                                                dimensions: ProductDimensions(length: "", width: "", height: ""), weight: "2",
                                                                virtual: true,
                                                                categories: [category])
        // downloadable: true, virtual: true, missing inventory/shipping/categories/brief description
        static let downloadableSimpleProduct = MockProduct().product(downloadable: true, briefDescription: "desc", productType: .simple,
                                                                     manageStock: true, sku: "uks", stockQuantity: nil,
                                                                     dimensions: ProductDimensions(length: "", width: "", height: ""), weight: "3",
                                                                     virtual: true,
                                                                     categories: [category])
    }
}
