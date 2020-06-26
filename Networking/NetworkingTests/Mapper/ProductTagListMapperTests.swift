import XCTest
@testable import Networking

final class ProductTagListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductTag Fields are parsed correctly.
    ///
    func testProductTagFieldsAreProperlyParsed() throws {
        let tags = try mapLoadAllProductTagsResponse()
        XCTAssertEqual(tags.count, 4)

        let secondTag = tags[1]
        XCTAssertEqual(secondTag.tagID, 35)
        XCTAssertEqual(secondTag.name, "Oxford Shoes")
        XCTAssertEqual(secondTag.slug, "oxford-shoes")
    }
}


/// Private Methods.
///
private extension ProductTagListMapperTests {

    /// Returns the ProductTagListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductTags(from filename: String) throws -> [ProductTag] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try ProductTagListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductTagListMapper output upon receiving `product-tags-all`
    ///
    func mapLoadAllProductTagsResponse() throws -> [ProductTag] {
        return try mapProductTags(from: "product-tags-all")
    }
}
