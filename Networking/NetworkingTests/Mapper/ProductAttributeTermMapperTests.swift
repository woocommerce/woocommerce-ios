import XCTest
@testable import Networking

final class ProductAttributeTermMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    func test_productAttributeTerm_fields_are_correctly_mapped() throws {
        let term = try mapLoadProductAttributeTermsResponse()

        let expectedTerm = ProductAttributeTerm(siteID: dummySiteID, termID: 23, name: "XXS", slug: "xxs", count: 1)

        XCTAssertEqual(term, expectedTerm)
    }

    func test_productAttributeTerm_fields_are_correctly_mapped_when_response_has_no_data_envelope() throws {
        let term = try mapLoadProductAttributeTermResponseWithoutDataEnvelope()

        let expectedTerm = ProductAttributeTerm(siteID: dummySiteID, termID: 23, name: "XXS", slug: "xxs", count: 1)

        XCTAssertEqual(term, expectedTerm)
    }
}

// MARK: Helpers
private extension ProductAttributeTermMapperTests {
    func mapProductAttributeTerm(from filename: String) throws -> ProductAttributeTerm {
        guard let response = Loader.contentsOf(filename) else {
            throw ParsingError.unableToLoadFile
        }

        return try ProductAttributeTermMapper(siteID: dummySiteID).map(response: response)
    }

    func mapLoadProductAttributeTermsResponse() throws -> ProductAttributeTerm {
        return try mapProductAttributeTerm(from: "attribute-term")
    }

    func mapLoadProductAttributeTermResponseWithoutDataEnvelope() throws -> ProductAttributeTerm {
        return try mapProductAttributeTerm(from: "attribute-term-without-data")
    }
}

private enum ParsingError: Error {
    case unableToLoadFile
}
