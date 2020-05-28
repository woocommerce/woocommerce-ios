import XCTest

@testable import WooCommerce
@testable import Yosemite

/// The same tests as `ProductFormActionsFactoryTests`, but with Edit Products M2 feature flag on.
/// When we fully launch Edit Products M2, we can replace `ProductFormActionsFactoryTests` with the test cases here.
///
final class ProductFormActionsFactory_EditProductsM2Tests: XCTestCase {
    func testViewModelForPhysicalSimpleProductWithoutImages() {
        // Arrange
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: false)

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .shippingSettings, .inventorySettings, .briefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormEditAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVirtualSimpleProductWithImages() {
        // Arrange
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: true,
                                            images: sampleImages())

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .inventorySettings, .briefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormEditAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForDownloadableSimpleProduct() {
        // Arrange
        let product = MockProduct().product(downloadable: true,
                                            name: "woo",
                                            productType: .simple)

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .inventorySettings, .briefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormEditAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVirtualSimpleProduct() {
        // Arrange
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: true)

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: true,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormEditAction] = [.images, .name, .description]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormEditAction] = [.priceSettings, .inventorySettings, .briefDescription]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormEditAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }
}

private extension ProductFormActionsFactory_EditProductsM2Tests {
    func sampleImages() -> [ProductImage] {
        let image1 = ProductImage(imageID: 19,
                                  dateCreated: Date(),
                                  dateModified: Date(),
                                  src: "https://photo.jpg",
                                  name: "Tshirt",
                                  alt: "")
        return [image1]
    }
}
