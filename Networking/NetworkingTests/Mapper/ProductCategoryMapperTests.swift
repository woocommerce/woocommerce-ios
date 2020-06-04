import XCTest
@testable import Networking


/// ProductCategoryMapper Unit Tests
///
final class ProductCategoryMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductCategory Fields are parsed correctly.
    ///
    func testProductCategoryFieldsAreProperlyParsed() throws {
        let productCategory = try mapProductCategoryResponse()
        XCTAssertNotNil(productCategory)

        XCTAssertEqual(productCategory?.categoryID, 104)
        XCTAssertEqual(productCategory?.parentID, 0)
        XCTAssertEqual(productCategory?.siteID, dummySiteID)
        XCTAssertEqual(productCategory?.name, "Dress")
        XCTAssertEqual(productCategory?.slug, "Shirt")
    }

}


/// Private Methods.
///
private extension ProductCategoryMapperTests {

    /// Returns the ProducCategoryMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductCategory(from filename: String) throws -> ProductCategory? {
        guard let response = Loader.contentsOf(filename) else {
            return nil
        }

        return try ProductCategoryMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductCategoryMapper output upon receiving `category`
    ///
    func mapProductCategoryResponse() throws -> ProductCategory? {
        return try mapProductCategory(from: "category")
    }
}
