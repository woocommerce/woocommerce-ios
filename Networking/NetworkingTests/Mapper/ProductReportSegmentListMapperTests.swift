import XCTest
@testable import Networking

final class ProductReportSegmentListMapperTests: XCTestCase {

    func test_product_segments_are_properly_parsed_with_data_envelope() throws {
        // When
        let segments = mapProductReportSegments(from: "product-report")

        // Then
        XCTAssertEqual(segments.count, 2)
        let firstItem = try XCTUnwrap(segments.first)
        XCTAssertEqual(firstItem.productID, 119)
        XCTAssertEqual(firstItem.productName, "Pesto Spaghetti")
        XCTAssertEqual(firstItem.subtotals.itemsSold, 1)

        let secondItem = try XCTUnwrap(segments.last)
        XCTAssertEqual(secondItem.productID, 134)
        XCTAssertEqual(secondItem.productName, "Fried-egg Bacon Bagel")
        XCTAssertEqual(secondItem.subtotals.itemsSold, 0)
    }

    func test_product_segments_are_properly_parsed_without_data_envelope() throws {
        // When
        let segments = mapProductReportSegments(from: "product-report-without-data-envelope")

        // Then
        XCTAssertEqual(segments.count, 2)
        let firstItem = try XCTUnwrap(segments.first)
        XCTAssertEqual(firstItem.productID, 119)
        XCTAssertEqual(firstItem.productName, "Pesto Spaghetti")
        XCTAssertEqual(firstItem.subtotals.itemsSold, 1)

        let secondItem = try XCTUnwrap(segments.last)
        XCTAssertEqual(secondItem.productID, 134)
        XCTAssertEqual(secondItem.productName, "Fried-egg Bacon Bagel")
        XCTAssertEqual(secondItem.subtotals.itemsSold, 0)
    }
}

private extension ProductReportSegmentListMapperTests {
    /// Returns the ProductReportSegmentListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapProductReportSegments(from filename: String) -> [ProductReportSegment] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! ProductReportSegmentListMapper().map(response: response)
    }
}
