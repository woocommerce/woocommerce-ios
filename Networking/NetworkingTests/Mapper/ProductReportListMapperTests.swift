import XCTest
@testable import Networking

final class ProductReportListMapperTests: XCTestCase {

    func test_product_reports_are_properly_parsed_with_data_envelope() throws {
        // When
        let list = mapProductReports(from: "product-report")

        // Then
        XCTAssertEqual(list.count, 1)
        let firstItem = try XCTUnwrap(list.first)
        XCTAssertEqual(firstItem.productID, 248)
        XCTAssertEqual(firstItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(firstItem.itemsSold, 8)
        XCTAssertEqual(firstItem.stockQuantity, 24)
        XCTAssertEqual(firstItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-laboriosam-300x300.png")
    }

    func test_product_reports_are_properly_parsed_without_data_envelope() throws {
        // When
        let list = mapProductReports(from: "product-report-without-data-envelope")

        // Then
        XCTAssertEqual(list.count, 1)
        let firstItem = try XCTUnwrap(list.first)
        XCTAssertEqual(firstItem.productID, 248)
        XCTAssertEqual(firstItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(firstItem.itemsSold, 8)
        XCTAssertEqual(firstItem.stockQuantity, 24)
        XCTAssertEqual(firstItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-laboriosam-300x300.png")
    }

    func test_product_reports_with_string_stock_quantity_are_properly_parsed() throws {
        // When
        let list = mapProductReports(from: "product-report-string-stock-quantity")

        // Then
        XCTAssertEqual(list.count, 1)
        let firstItem = try XCTUnwrap(list.first)
        XCTAssertEqual(firstItem.productID, 248)
        XCTAssertEqual(firstItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(firstItem.itemsSold, 8)
        XCTAssertEqual(firstItem.stockQuantity, 55.4)
        XCTAssertEqual(firstItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-laboriosam-300x300.png")
    }

    func test_variation_reports_are_properly_parsed() throws {
        // When
        let list = mapProductReports(from: "variation-report")

        // Then
        XCTAssertEqual(list.count, 1)
        let firstItem = try XCTUnwrap(list.first)
        XCTAssertEqual(firstItem.productID, 248)
        XCTAssertEqual(firstItem.variationID, 280)
        XCTAssertEqual(firstItem.name, "Fantastic Concrete Shirt")
        XCTAssertEqual(firstItem.itemsSold, 8)
        XCTAssertEqual(firstItem.stockQuantity, 24)
        XCTAssertEqual(firstItem.imageURL?.absoluteString, "https://test.ninja/wp-content/uploads/2024/05/img-laboriosam-300x300.png")
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
