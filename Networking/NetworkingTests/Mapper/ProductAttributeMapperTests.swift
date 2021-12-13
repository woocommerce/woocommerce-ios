import XCTest
@testable import Networking


/// ProductAttributeMapper Unit Tests
///
final class ProductAttributeMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductAttribute Fields are parsed correctly.
    ///
    func test_ProductAttribute_fields_are_properly_parsed() throws {
        let productAttribute = try XCTUnwrap(mapProductAttributeResponse())

        XCTAssertEqual(productAttribute.attributeID, 1)
        XCTAssertEqual(productAttribute.name, "Color")
        XCTAssertEqual(productAttribute.position, 0)
        XCTAssertEqual(productAttribute.visible, true)
        XCTAssertEqual(productAttribute.variation, true)
        XCTAssertEqual(productAttribute.options, [])
    }

}


/// Private Methods.
///
private extension ProductAttributeMapperTests {

    /// Returns the ProductAttributeMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductAttribute(from filename: String) throws -> ProductAttribute? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try ProductAttributeMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductAttributeMapper output upon receiving `product-attribute-create`
    ///
    func mapProductAttributeResponse() throws -> ProductAttribute? {
        return try mapProductAttribute(from: "product-attribute-create")
    }
}
