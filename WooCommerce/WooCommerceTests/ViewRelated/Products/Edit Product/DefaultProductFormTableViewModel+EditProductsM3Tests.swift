import XCTest

@testable import WooCommerce
@testable import Yosemite

/// The same tests as `DefaultProductFormTableViewModel_EditProductsM2Tests`, but with Edit Products M2 and M3 feature flag on.
/// When we fully launch Edit Products M2 and M3, we can replace `DefaultProductFormTableViewModel_EditProductsM2Tests` with the test cases here.
///
final class DefaultProductFormTableViewModel_EditProductsM3Tests: XCTestCase {

    private let mockFeatureFlagService = MockFeatureFlagService(isEditProductsRelease2On: true, isEditProductsRelease3On: true)

    func testViewModelForSimplePhysicalProductWithoutImages() {
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: false)
        let viewModel = DefaultProductFormTableViewModel(product: product,
                                                         currency: "$",
                                                         featureFlagService: mockFeatureFlagService)
        let primaryFieldsSection = ProductFormSection.primaryFields(rows: [
            .images(product: product),
            .name(name: product.name),
            .description(description: product.trimmedFullDescription)
        ])
        XCTAssertEqual(viewModel.sections[0], primaryFieldsSection)

        let settingFieldsSection = viewModel.sections[1]
        switch settingFieldsSection {
        case .settings(let rows):
            XCTAssertEqual(rows.count, 5)

            if case .price(_) = rows[0] {} else {
                XCTFail("Unexpected setting section: \(rows[0])")
            }
            if case .shipping(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .inventory(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[2])")
            }
            if case .categories(_) = rows[3] {} else {
                XCTFail("Unexpected setting section: \(rows[3])")
            }
            if case .briefDescription(_) = rows[4] {} else {
                XCTFail("Unexpected setting section: \(rows[4])")
            }
        default:
            XCTFail("Unexpected section: \(settingFieldsSection)")
        }
    }

    func testViewModelForPhysicalSimpleProductWithImages() {
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: true,
                                            images: sampleImages())
        let viewModel = DefaultProductFormTableViewModel(product: product,
                                                         currency: "$",
                                                         featureFlagService: mockFeatureFlagService)
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
            if case .inventory(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .categories(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[2])")
            }
            if case .briefDescription(_) = rows[3] {} else {
                XCTFail("Unexpected setting section: \(rows[3])")
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
                                                         featureFlagService: mockFeatureFlagService)
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
            if case .inventory(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .categories(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[2])")
            }
            if case .briefDescription(_) = rows[3] {} else {
                XCTFail("Unexpected setting section: \(rows[3])")
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
                                                         featureFlagService: mockFeatureFlagService)
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
            if case .inventory(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .categories(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[2])")
            }
            if case .briefDescription(_) = rows[3] {} else {
                XCTFail("Unexpected setting section: \(rows[3])")
            }
        default:
            XCTFail("Unexpected section: \(settingFieldsSection)")
        }
    }
}

private extension DefaultProductFormTableViewModel_EditProductsM3Tests {
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
