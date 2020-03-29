import XCTest
@testable import Networking

final class ProductCategoryListMapperTests: XCTestCase {

    /// Verifies that all of the ProductCatefory Fields are parsed correctly.
    ///
    func testProductReviewFieldsAreProperlyParsed() throws {
        let productCategories = try mapLoadAllProductCategoriesResponse()
        XCTAssertEqual(productCategories.count, 2)

        let firstProductCategory = productCategories[0]
        XCTAssertEqual(firstProductCategory.categoryID, 104)
        XCTAssertEqual(firstProductCategory.name, "Dress")
        XCTAssertEqual(firstProductCategory.slug, "Shirt")
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

        return try ProductCategoryListMapper().map(response: response)
    }

    /// Returns the ProductListMapper output upon receiving `reviews-all`
    ///
    func mapLoadAllProductCategoriesResponse() throws -> [ProductCategory] {
        return try mapProductCategories(from: "categories-all")
    }
}
