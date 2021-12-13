import XCTest
@testable import Networking


/// ProductAttributeListMapper Unit Tests
///
final class ProductAttributeListMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductAttribute Fields are parsed correctly.
    ///
    func test_ProductAttribute_fields_are_properly_parsed() throws {
        let productAttributes = try mapProductAttributesResponse()
        XCTAssertEqual(productAttributes.count, 2)

        let secondProductAttribute = productAttributes[1]

        XCTAssertEqual(secondProductAttribute.attributeID, 2)
        XCTAssertEqual(secondProductAttribute.name, "Size")
        XCTAssertEqual(secondProductAttribute.position, 0)
        XCTAssertEqual(secondProductAttribute.visible, true)
        XCTAssertEqual(secondProductAttribute.variation, true)
        XCTAssertEqual(secondProductAttribute.options, [])
    }

}


/// Private Methods.
///
private extension ProductAttributeListMapperTests {

    /// Returns the ProductAttributeMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductAttribute(from filename: String) throws -> [ProductAttribute] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try ProductAttributeListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductAttributeListMapper output upon receiving `product-attribute-all`
    ///
    func mapProductAttributesResponse() throws -> [ProductAttribute] {
        return try mapProductAttribute(from: "product-attributes-all")
    }
}
