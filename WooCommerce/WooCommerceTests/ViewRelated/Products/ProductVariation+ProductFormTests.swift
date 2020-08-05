import XCTest

@testable import WooCommerce
import Yosemite

/// Tests on `ProductFormDataModel` helpers for a `ProductVariation`.
final class ProductVariation_ProductFormTests: XCTestCase {
    // MARK: - `name`

    func testNameReturnsMultipleAttributes() {
        let attributeOptions = ["Strawberry", "Vanilla", "Sprinkles"]
        let attributes: [ProductVariationAttribute] = attributeOptions.map { ProductVariationAttribute(id: 0, name: "", option: $0) }
        let productVariation = MockProductVariation().productVariation().copy(attributes: attributes)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let expectedName = attributeOptions.joined(separator: " - ")
        XCTAssertEqual(model.name, expectedName)
    }

    // MARK: - `trimmedFullDescription`

    func testTrimmedFullDescriptionWithLeadingNewLinesAndHTMLTags() {
        let description = "\n\n\n  <p>This is the party room!</p>\n"
        let productVariation = MockProductVariation().productVariation().copy(description: description)
        let model = EditableProductVariationModel(productVariation: productVariation)
        let expectedDescription = "This is the party room!"
        XCTAssertEqual(model.trimmedFullDescription, expectedDescription)
    }

    // MARK: - `isShippingEnabled`

    func testShippingIsEnabledForAPhysicalProductVariation() {
        let productVariation = MockProductVariation().productVariation().copy(virtual: false, downloadable: false)
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertTrue(model.isShippingEnabled())
    }

    func testShippingIsDisabledForADownloadableProductVariation() {
        let productVariation = MockProductVariation().productVariation().copy(virtual: false, downloadable: true)
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertFalse(model.isShippingEnabled())
    }

    func testShippingIsDisabledForAVirtualProductVariation() {
        let productVariation = MockProductVariation().productVariation().copy(virtual: true, downloadable: false)
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertFalse(model.isShippingEnabled())
    }

    // MARK: image related

    func testProductVariationDoesNotAllowMultipleImages() {
        let productVariation = MockProductVariation().productVariation().copy(image: nil)
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertFalse(model.allowsMultipleImages())
    }

    func testProductVariationImageDeletionIsDisabled() {
        let productVariation = MockProductVariation().productVariation().copy(image: nil)
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertFalse(model.isImageDeletionEnabled())
    }

    // MARK: `productTaxStatus`

    func testProductTaxStatusFromAnUnexpectedRawValueReturnsDefaultTaxable() {
        let productVariation = MockProductVariation().productVariation().copy(taxStatusKey: "unknown tax status")
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertEqual(model.productTaxStatus, .taxable)
    }

    func testProductTaxStatusFromAValidRawValueReturnsTheCorrespondingCase() {
        let productVariation = MockProductVariation().productVariation().copy(taxStatusKey: ProductTaxStatus.shipping.rawValue)
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertEqual(model.productTaxStatus, .shipping)
    }

    // MARK: `backordersSetting`

    func testBackordersSettingFromAnUnexpectedRawValueReturnsACustomCase() {
        let rawValue = "unknown setting"
        let productVariation = MockProductVariation().productVariation().copy(backordersKey: rawValue)
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertEqual(model.backordersSetting, .custom(rawValue))
    }

    func testBackordersSettingFromAValidRawValueReturnsTheCorrespondingCase() {
        let productVariation = MockProductVariation().productVariation().copy(backordersKey: ProductBackordersSetting.notAllowed.rawValue)
        let model = EditableProductVariationModel(productVariation: productVariation)
        XCTAssertEqual(model.backordersSetting, .notAllowed)
    }
}
