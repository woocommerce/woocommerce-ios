import XCTest
@testable import Networking


/// ProductTagMapper Unit Tests
///
final class ProductTagMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductTag Fields are parsed correctly.
    ///
    func testProductTagFieldsAreProperlyParsed() throws {
        let tag = try XCTUnwrap(mapProductTagResponse())

        XCTAssertEqual(tag.tagID, 34)
        XCTAssertEqual(tag.name, "Leather Shoes")
        XCTAssertEqual(tag.slug, "leather-shoes")
    }

}


/// Private Methods.
///
private extension ProductTagMapperTests {

    /// Returns the ProducTagMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductTag(from filename: String) throws -> ProductTag? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try ProductTagMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductTagMapper output upon receiving `product-tag`
    ///
    func mapProductTagResponse() throws -> ProductTag? {
        return try mapProductTag(from: "product-tag")
    }
}
