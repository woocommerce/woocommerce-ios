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
    func test_ProductAttribute_fields_are_properly_parsed() async throws {
        let productAttribute = try await mapProductAttributeResponse()

        XCTAssertEqual(productAttribute.attributeID, 1)
        XCTAssertEqual(productAttribute.name, "Color")
        XCTAssertEqual(productAttribute.position, 0)
        XCTAssertEqual(productAttribute.visible, true)
        XCTAssertEqual(productAttribute.variation, true)
        XCTAssertEqual(productAttribute.options, [])
    }

    /// Verifies that all of the ProductAttribute Fields are parsed correctly when response has no data envelope
    ///
    func test_ProductAttribute_fields_are_properly_parsed_when_response_has_no_data_envelope() async throws {
        let productAttribute = try await mapProductAttributeResponseWithoutDataEnvelope()

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
    func mapProductAttribute(from filename: String) async throws -> ProductAttribute {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await ProductAttributeMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductAttributeMapper output upon receiving `product-attribute-create`
    ///
    func mapProductAttributeResponse() async throws -> ProductAttribute {
        try await mapProductAttribute(from: "product-attribute-create")
    }

    /// Returns the ProductAttributeMapper output upon receiving `product-attribute-create-without-data`
    ///
    func mapProductAttributeResponseWithoutDataEnvelope() async throws -> ProductAttribute {
        try await mapProductAttribute(from: "product-attribute-create-without-data")
    }

    struct FileNotFoundError: Error {}
}
