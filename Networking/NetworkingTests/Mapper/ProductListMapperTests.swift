import XCTest
@testable import Networking


/// ProductListMapper Unit Tests
///
class ProductListMapperTests: XCTestCase {
    /// Verifies that all of the Product Fields are parsed correctly.
    ///
    func testProductFieldsAreProperlyParsed() {
        let products = mapLoadAllProductsResponse()
        XCTAssert(products.count == 142)

        let firstProduct = products[0]
        let dateCreated = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-02-19T17:33:31")
        let dateModified = DateFormatter.Defaults.dateTimeFormatter.date(from: "2019-02-19T17:48:01")

        XCTAssertEqual(firstProduct.productID, 282)
    }
}


/// Private Methods.
///
private extension ProductListMapperTests {

    /// Returns the OrderListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProducts(from filename: String) -> [Product] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! ProductListMapper().map(response: response)
    }

    /// Returns the OrderListMapper output upon receiving `orders-load-all`
    ///
    func mapLoadAllProductsResponse() -> [Product] {
        return mapProducts(from: "products-load-all")
    }
}
