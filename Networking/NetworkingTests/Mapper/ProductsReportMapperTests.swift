import XCTest
@testable import Networking

final class ProductsReportMapperTests: XCTestCase {

    /// Verifies that the whole list is parsed.
    ///
    func test_mapper_parses_all_products_in_response() async throws {
        // Given
        let products = try await mapLoadProductsReportResponseWithDataEnvelope()

        // Then
        XCTAssertEqual(products.count, 2)
    }

    /// Verifies that the whole list is parsed.
    ///
    func test_mapper_parses_all_products_in_response_without_data_envelope() async throws {
        // Given
        let products = try await mapLoadProductsReportResponseWithoutDataEnvelope()

        // Then
        XCTAssertEqual(products.count, 2)
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_mapper_parses_all_fields_in_result() async throws {
        // Given
        let products = try await mapLoadProductsReportResponseWithDataEnvelope()
        let product = products[0]
        let expectedProduct = ProductsReportItem(productID: 233,
                                                 productName: "Colorful Sunglasses Subscription",
                                                 quantity: 5,
                                                 price: 5,
                                                 total: 177,
                                                 imageUrl: "https://example.com/wp-content/uploads/2023/01/sunglasses-2-600x600.jpg")

        // Then
        XCTAssertEqual(product, expectedProduct)
    }
}

// MARK: - Test Helpers
///
private extension ProductsReportMapperTests {

    /// Returns the ProductsReportMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapReport(from filename: String) async throws -> [ProductsReportItem] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try await ProductsReportMapper().map(response: response)
    }

    /// Returns the ProductsReportItem list from `coupon-reports.json`
    ///
    func mapLoadProductsReportResponseWithDataEnvelope() async throws -> [ProductsReportItem] {
        try await mapReport(from: "reports-products")
    }

    /// Returns the ProductsReportItem list from `coupon-reports-without-data.json`
    ///
    func mapLoadProductsReportResponseWithoutDataEnvelope() async throws -> [ProductsReportItem] {
        try await mapReport(from: "reports-products-without-data")
    }
}
