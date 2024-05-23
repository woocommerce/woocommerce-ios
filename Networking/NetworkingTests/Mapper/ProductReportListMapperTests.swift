import XCTest
@testable import Networking

final class ProductReportListMapperTests: XCTestCase {

    func test_product_reports_are_properly_parsed_with_data_envelope() throws {
        // When
        let list = mapProductReports(from: "product-report")

        // Then
        XCTAssertEqual(list.count, 2)
        let firstItem = try XCTUnwrap(list.first)
        XCTAssertEqual(firstItem.productID, 248)
        XCTAssertEqual(firstItem.variationID, 280)
        XCTAssertEqual(firstItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(firstItem.itemsSold, 8)
        XCTAssertEqual(firstItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-laboriosam-300x300.png")

        let secondItem = try XCTUnwrap(list.last)
        XCTAssertEqual(secondItem.productID, 248)
        XCTAssertEqual(secondItem.variationID, 277)
        XCTAssertEqual(secondItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(secondItem.itemsSold, 7)
        XCTAssertEqual(secondItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-vel-300x300.png")
    }

    func test_product_reports_are_properly_parsed_without_data_envelope() throws {
        // When
        let list = mapProductReports(from: "product-report-without-data-envelope")

        // Then
        XCTAssertEqual(list.count, 2)
        let firstItem = try XCTUnwrap(list.first)
        XCTAssertEqual(firstItem.productID, 248)
        XCTAssertEqual(firstItem.variationID, 280)
        XCTAssertEqual(firstItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(firstItem.itemsSold, 8)
        XCTAssertEqual(firstItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-laboriosam-300x300.png")

        let secondItem = try XCTUnwrap(list.last)
        XCTAssertEqual(secondItem.productID, 248)
        XCTAssertEqual(secondItem.variationID, 277)
        XCTAssertEqual(secondItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(secondItem.itemsSold, 7)
        XCTAssertEqual(secondItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-vel-300x300.png")
    }
}

private extension ProductReportListMapperTests {
    /// Returns the ProductReportListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductReports(from filename: String) -> [ProductReport] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! ProductReportListMapper().map(response: response)
    }
}
