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
    func test_ProductAttribute_fields_are_properly_parsed() async throws {
        let productAttributes = try await mapProductAttributesResponse()
        XCTAssertEqual(productAttributes.count, 2)

        let secondProductAttribute = productAttributes[1]

        XCTAssertEqual(secondProductAttribute.attributeID, 2)
        XCTAssertEqual(secondProductAttribute.name, "Size")
        XCTAssertEqual(secondProductAttribute.position, 0)
        XCTAssertEqual(secondProductAttribute.visible, true)
        XCTAssertEqual(secondProductAttribute.variation, true)
        XCTAssertEqual(secondProductAttribute.options, [])
    }

    /// Verifies that all of the ProductAttribute Fields are parsed correctly when response has no data envelope
    ///
    func test_ProductAttribute_fields_are_properly_parsed_when_response_has_no_data_envelope() async throws {
        let productAttributes = try await mapProductAttributeResponseWithoutDataEnvelope()
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
    func mapProductAttribute(from filename: String) async throws -> [ProductAttribute] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try await ProductAttributeListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductAttributeListMapper output upon receiving `product-attribute-all`
    ///
    func mapProductAttributesResponse() async throws -> [ProductAttribute] {
        try await mapProductAttribute(from: "product-attributes-all")
    }

    /// Returns the ProductAttributeListMapper output upon receiving `product-attributes-all-without-data`
    ///
    func mapProductAttributeResponseWithoutDataEnvelope() async throws -> [ProductAttribute] {
        try await mapProductAttribute(from: "product-attributes-all-without-data")
    }}
