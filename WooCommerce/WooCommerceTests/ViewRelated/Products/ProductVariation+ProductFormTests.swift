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
        let expectedName = attributeOptions.joined(separator: " - ")
        XCTAssertEqual(productVariation.name, expectedName)
    }

    // MARK: - `trimmedFullDescription`

    func testTrimmedFullDescriptionWithLeadingNewLinesAndHTMLTags() {
        let description = "\n\n\n  <p>This is the party room!</p>\n"
        let productVariation = MockProductVariation().productVariation().copy(description: description)
        let expectedDescription = "This is the party room!"
        XCTAssertEqual(productVariation.trimmedFullDescription, expectedDescription)
    }

    // MARK: - `isShippingEnabled`

    func testShippingIsEnabledForAPhysicalProductVariation() {
        let productVariation = MockProductVariation().productVariation().copy(virtual: false, downloadable: false)
        XCTAssertTrue(productVariation.isShippingEnabled)
    }

    func testShippingIsDisabledForADownloadableProductVariation() {
        let productVariation = MockProductVariation().productVariation().copy(virtual: false, downloadable: true)
        XCTAssertFalse(productVariation.isShippingEnabled)
    }

    func testShippingIsDisabledForAVirtualProductVariation() {
        let productVariation = MockProductVariation().productVariation().copy(virtual: true, downloadable: false)
        XCTAssertFalse(productVariation.isShippingEnabled)
    }

    // MARK: image related

    func testProductVariationDoesNotAllowMultipleImages() {
        let productVariation = MockProductVariation().productVariation().copy(image: nil)
        XCTAssertFalse(productVariation.allowsMultipleImages())
    }

    func testProductVariationImageDeletionIsDisabled() {
        let productVariation = MockProductVariation().productVariation().copy(image: nil)
        XCTAssertFalse(productVariation.isImageDeletionEnabled())
    }

    // MARK: `productTaxStatus`

    func testProductTaxStatusFromAnUnexpectedRawValueReturnsDefaultTaxable() {
        let productVariation = MockProductVariation().productVariation().copy(taxStatusKey: "unknown tax status")
        XCTAssertEqual(productVariation.productTaxStatus, .taxable)
    }

    func testProductTaxStatusFromAValidRawValueReturnsTheCorrespondingCase() {
        let productVariation = MockProductVariation().productVariation().copy(taxStatusKey: ProductTaxStatus.shipping.rawValue)
        XCTAssertEqual(productVariation.productTaxStatus, .shipping)
    }

    // MARK: `backordersSetting`

    func testBackordersSettingFromAnUnexpectedRawValueReturnsACustomCase() {
        let rawValue = "unknown setting"
        let productVariation = MockProductVariation().productVariation().copy(backordersKey: rawValue)
        XCTAssertEqual(productVariation.backordersSetting, .custom(rawValue))
    }

    func testBackordersSettingFromAValidRawValueReturnsTheCorrespondingCase() {
        let productVariation = MockProductVariation().productVariation().copy(backordersKey: ProductBackordersSetting.notAllowed.rawValue)
        XCTAssertEqual(productVariation.backordersSetting, .notAllowed)
    }
}
