import XCTest

@testable import WooCommerce
@testable import Yosemite

final class ProductFormActionsFactoryTests: XCTestCase {
    func testViewModelForSimplePhysicalProductWithoutImagesWhenM2FeatureFlagIsOff() {
        // Arrange
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: false)

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: false,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormAction] = [.editName, .editDescription]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormAction] = [.editPriceSettings, .editShippingSettings, .editInventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVirtualProductWithImages() {
        // Arrange
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: true,
                                            images: sampleImages())

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: false,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormAction] = [.editImages, .editName, .editDescription]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormAction] = [.editPriceSettings, .editInventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForDownloadableSimpleProduct() {
        // Arrange
        let product = MockProduct().product(downloadable: true,
                                            name: "woo",
                                            productType: .simple)

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: false,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormAction] = [.editName, .editDescription]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormAction] = [.editPriceSettings, .editInventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }

    func testViewModelForVirtualProductWithoutImages() {
        // Arrange
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: true)

        // Action
        let factory = ProductFormActionsFactory(product: product,
                                                isEditProductsRelease2Enabled: false,
                                                isEditProductsRelease3Enabled: false)

        // Assert
        let expectedPrimarySectionActions: [ProductFormAction] = [.editName, .editDescription]
        XCTAssertEqual(factory.primarySectionActions(), expectedPrimarySectionActions)

        let expectedSettingsSectionActions: [ProductFormAction] = [.editPriceSettings, .editInventorySettings]
        XCTAssertEqual(factory.settingsSectionActions(), expectedSettingsSectionActions)

        let expectedBottomSheetActions: [ProductFormAction] = []
        XCTAssertEqual(factory.bottomSheetActions(), expectedBottomSheetActions)
    }
}

private extension ProductFormActionsFactoryTests {
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
