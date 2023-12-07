import XCTest
@testable import Networking

final class ProductAttributeTermMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    func test_productAttributeTerm_fields_are_correctly_mapped() async throws {
        let term = try await mapLoadProductAttributeTermsResponse()

        let expectedTerm = ProductAttributeTerm(siteID: dummySiteID, termID: 23, name: "XXS", slug: "xxs", count: 1)

        XCTAssertEqual(term, expectedTerm)
    }

    func test_productAttributeTerm_fields_are_correctly_mapped_when_response_has_no_data_envelope() async throws {
        let term = try await mapLoadProductAttributeTermResponseWithoutDataEnvelope()

        let expectedTerm = ProductAttributeTerm(siteID: dummySiteID, termID: 23, name: "XXS", slug: "xxs", count: 1)

        XCTAssertEqual(term, expectedTerm)
    }
}

// MARK: Helpers
private extension ProductAttributeTermMapperTests {
    func mapProductAttributeTerm(from filename: String) async throws -> ProductAttributeTerm {
        guard let response = Loader.contentsOf(filename) else {
            throw ParsingError.unableToLoadFile
        }

        return try await ProductAttributeTermMapper(siteID: dummySiteID).map(response: response)
    }

    func mapLoadProductAttributeTermsResponse() async throws -> ProductAttributeTerm {
        try await mapProductAttributeTerm(from: "attribute-term")
    }

    func mapLoadProductAttributeTermResponseWithoutDataEnvelope() async throws -> ProductAttributeTerm {
        try await mapProductAttributeTerm(from: "attribute-term-without-data")
    }
}

private enum ParsingError: Error {
    case unableToLoadFile
}
