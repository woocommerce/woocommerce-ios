import XCTest
@testable import Networking

final class ProductCategoryListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 33334444

    /// Verifies that all of the ProductCategory Fields are parsed correctly.
    ///
    func testProductCategoryFieldsAreProperlyParsed() throws {
        let productCategories = try mapLoadAllProductCategoriesResponse()
        XCTAssertEqual(productCategories.count, 2)

        let secondProductCategory = productCategories[1]
        XCTAssertEqual(secondProductCategory.categoryID, 20)
        XCTAssertEqual(secondProductCategory.parentID, 17)
        XCTAssertEqual(secondProductCategory.siteID, dummySiteID)
        XCTAssertEqual(secondProductCategory.name, "American")
        XCTAssertEqual(secondProductCategory.slug, "american")
    }
}


/// Private Methods.
///
private extension ProductCategoryListMapperTests {

    /// Returns the ProducCategoryListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductCategories(from filename: String) throws -> [ProductCategory] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try ProductCategoryListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the ProductListMapper output upon receiving `categories-all`
    ///
    func mapLoadAllProductCategoriesResponse() throws -> [ProductCategory] {
        return try mapProductCategories(from: "categories-all")
    }
}
