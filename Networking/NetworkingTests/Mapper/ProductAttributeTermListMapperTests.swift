import XCTest
@testable import Networking

final class ProductAttributeTermListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    func test_productAttributeTerm_fields_are_correctly_mapped() async throws {
        let terms = try await mapLoadAllProductAttributeTermsResponse()
        XCTAssertEqual(terms.count, 3)

        let secondTerm = terms[1]
        let expectedTerm = ProductAttributeTerm(siteID: dummySiteID, termID: 27, name: "Medium", slug: "medium", count: 1)

        XCTAssertEqual(secondTerm, expectedTerm)
    }

    func test_productAttributeTerm_fields_are_correctly_mapped_when_response_has_no_data_envelope() async throws {
        let terms = try await mapLoadAllProductAttributeTermsResponseWithoutDataEnvelope()
        XCTAssertEqual(terms.count, 3)

        let secondTerm = terms[1]
        let expectedTerm = ProductAttributeTerm(siteID: dummySiteID, termID: 27, name: "Medium", slug: "medium", count: 1)

        XCTAssertEqual(secondTerm, expectedTerm)
    }
}

// MARK: Helpers
private extension ProductAttributeTermListMapperTests {
    func mapProductAttributeTerms(from filename: String) async throws -> [ProductAttributeTerm] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try await ProductAttributeTermListMapper(siteID: dummySiteID).map(response: response)
    }

    func mapLoadAllProductAttributeTermsResponse() async throws -> [ProductAttributeTerm] {
        return try await mapProductAttributeTerms(from: "product-attribute-terms")
    }

    func mapLoadAllProductAttributeTermsResponseWithoutDataEnvelope() async throws -> [ProductAttributeTerm] {
        return try await mapProductAttributeTerms(from: "product-attribute-terms-without-data")
    }
}
