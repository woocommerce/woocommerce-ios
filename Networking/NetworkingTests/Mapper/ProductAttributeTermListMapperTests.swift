import XCTest
@testable import Networking

final class ProductAttributeTermListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    func test_productAttributeTerm_fields_are_correctly_mapped() throws {
        let terms = try mapLoadAllProductAttributeTermsResponse()
        XCTAssertEqual(terms.count, 3)

        let secondTerm = terms[1]
        let expectedTerm = ProductAttributeTerm(siteID: dummySiteID, termID: 27, name: "Medium", slug: "medium", count: 1)

        XCTAssertEqual(secondTerm, expectedTerm)
    }
}

// MARK: Helpers
private extension ProductAttributeTermListMapperTests {
    func mapProductAttributeTerms(from filename: String) throws -> [ProductAttributeTerm] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try ProductAttributeTermListMapper(siteID: dummySiteID).map(response: response)
    }

    func mapLoadAllProductAttributeTermsResponse() throws -> [ProductAttributeTerm] {
        return try mapProductAttributeTerms(from: "product-attribute-terms")
    }
}
