import XCTest

@testable import WooCommerce
@testable import Yosemite

final class DefaultProductFormTableViewModelTests: XCTestCase {
    func testViewModelForSimplePhysicalProductWithoutImagesWhenM2FeatureFlagIsOff() {
        let product = MockProduct().product(downloadable: false,
                                            name: "woo",
                                            productType: .simple,
                                            virtual: false)
        let viewModel = DefaultProductFormTableViewModel(product: product,
                                                         currency: "$",
                                                         isEditProductsRelease2Enabled: false,
                                                         isEditProductsRelease3Enabled: false)
        let primaryFieldsSection = ProductFormSection.primaryFields(rows: [
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
            if case .shipping(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
            if case .inventory(_) = rows[2] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
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
                                                         isEditProductsRelease2Enabled: false,
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
            XCTAssertEqual(rows.count, 2)
            
            if case .price(_) = rows[0] {} else {
                XCTFail("Unexpected setting section: \(rows[0])")
            }
            if case .inventory(_) = rows[1] {} else {
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
                                                         isEditProductsRelease2Enabled: false,
                                                         isEditProductsRelease3Enabled: false)
        let primaryFieldsSection = ProductFormSection.primaryFields(rows: [
            .name(name: product.name),
            .description(description: product.trimmedFullDescription)
        ])
        XCTAssertEqual(viewModel.sections[0], primaryFieldsSection)
        
        let settingFieldsSection = viewModel.sections[1]
        switch settingFieldsSection {
        case .settings(let rows):
            XCTAssertEqual(rows.count, 2)
            if case .price(_) = rows[0] {} else {
                XCTFail("Unexpected setting section: \(rows[0])")
            }
            if case .inventory(_) = rows[1] {} else {
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
                                                         isEditProductsRelease2Enabled: false,
                                                         isEditProductsRelease3Enabled: false)
        let primaryFieldsSection = ProductFormSection.primaryFields(rows: [
            .name(name: product.name),
            .description(description: product.trimmedFullDescription)
        ])
        XCTAssertEqual(viewModel.sections[0], primaryFieldsSection)
        
        let settingFieldsSection = viewModel.sections[1]
        switch settingFieldsSection {
        case .settings(let rows):
            XCTAssertEqual(rows.count, 2)
            if case .price(_) = rows[0] {} else {
                XCTFail("Unexpected setting section: \(rows[0])")
            }
            if case .inventory(_) = rows[1] {} else {
                XCTFail("Unexpected setting section: \(rows[1])")
            }
        default:
            XCTFail("Unexpected section: \(settingFieldsSection)")
        }
    }
}

private extension DefaultProductFormTableViewModelTests {
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
