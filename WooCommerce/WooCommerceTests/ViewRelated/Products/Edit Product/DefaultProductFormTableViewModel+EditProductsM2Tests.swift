import XCTest

@testable import WooCommerce
@testable import Yosemite

/// The same tests as `DefaultProductFormTableViewModelTests`, but with Edit Products M2 feature flag on.
/// When we fully launch Edit Products M2, we can replace `DefaultProductFormTableViewModelTests` with the test cases here.
///
final class DefaultProductFormTableViewModel_EditProductsM2Tests: XCTestCase {
    func testViewModelForPhysicalSimpleProductWithoutImages() {
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: false)
        let viewModel = DefaultProductFormTableViewModel(product: product,
                                                         currency: "$",
                                                         isEditProductsRelease2Enabled: true,
                                                         isEditProductsRelease3Enabled: false)
        let primaryFieldsSection = ProductFormSection.primaryFields(rows: [
            .images(product: product),
            .name(name: product.name),
            .description(description: product.trimmedFullDescription)
        ])
        XCTAssertEqual(viewModel.sections[0], primaryFieldsSection)

        let settingFieldsSection = viewModel.sections[1]
        switch settingFieldsSection {
        case .settings(let rows):
            XCTAssertEqual(rows.count, 4)

            if case .price(_) = rows[0] {} else {
                XCTFail("Unexpected setting section: \(rows[0])")
            }
            if case .shipping(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .inventory(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .briefDescription(_) = rows[3] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
        default:
            XCTFail("Unexpected section: \(settingFieldsSection)")
        }
    }

    func testViewModelForVirtualSimpleProductWithImages() {
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: true,
                                            images: sampleImages())
        let viewModel = DefaultProductFormTableViewModel(product: product,
                                                         currency: "$",
                                                         isEditProductsRelease2Enabled: true,
                                                         isEditProductsRelease3Enabled: false)
        let primaryFieldsSection = ProductFormSection.primaryFields(rows: [
            .images(product: product),
            .name(name: product.name),
            .description(description: product.trimmedFullDescription)
        ])
        XCTAssertEqual(viewModel.sections[0], primaryFieldsSection)

        let settingFieldsSection = viewModel.sections[1]
        switch settingFieldsSection {
        case .settings(let rows):
            XCTAssertEqual(rows.count, 3)

            if case .price(_) = rows[0] {} else {
                XCTFail("Unexpected setting section: \(rows[0])")
            }
            if case .inventory(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .briefDescription(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
        default:
            XCTFail("Unexpected section: \(settingFieldsSection)")
        }
    }

    func testViewModelForDownloadableSimpleProduct() {
        let product = MockProduct().product(downloadable: true,
                                            name: "woo",
                                            productType: .simple)
        let viewModel = DefaultProductFormTableViewModel(product: product,
                                                         currency: "$",
                                                         isEditProductsRelease2Enabled: true,
                                                         isEditProductsRelease3Enabled: false)
        let primaryFieldsSection = ProductFormSection.primaryFields(rows: [
            .images(product: product),
            .name(name: product.name),
            .description(description: product.trimmedFullDescription)
        ])
        XCTAssertEqual(viewModel.sections[0], primaryFieldsSection)

        let settingFieldsSection = viewModel.sections[1]
        switch settingFieldsSection {
        case .settings(let rows):
            XCTAssertEqual(rows.count, 3)
            if case .price(_) = rows[0] {} else {
                XCTFail("Unexpected setting section: \(rows[0])")
            }
            if case .inventory(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .briefDescription(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
        default:
            XCTFail("Unexpected section: \(settingFieldsSection)")
        }
    }

    func testViewModelForVirtualSimpleProduct() {
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: true)
        let viewModel = DefaultProductFormTableViewModel(product: product,
                                                         currency: "$",
                                                         isEditProductsRelease2Enabled: true,
                                                         isEditProductsRelease3Enabled: false)
        let primaryFieldsSection = ProductFormSection.primaryFields(rows: [
            .images(product: product),
            .name(name: product.name),
            .description(description: product.trimmedFullDescription)
        ])
        XCTAssertEqual(viewModel.sections[0], primaryFieldsSection)

        let settingFieldsSection = viewModel.sections[1]
        switch settingFieldsSection {
        case .settings(let rows):
            XCTAssertEqual(rows.count, 3)
            if case .price(_) = rows[0] {} else {
                XCTFail("Unexpected setting section: \(rows[0])")
            }
            if case .inventory(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .briefDescription(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
        default:
            XCTFail("Unexpected section: \(settingFieldsSection)")
        }
    }
}

private extension DefaultProductFormTableViewModel_EditProductsM2Tests {
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
