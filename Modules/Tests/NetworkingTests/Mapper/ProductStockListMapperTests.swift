import XCTest
@testable import Networking

final class ProductStockListMapperTests: XCTestCase {
    private let sampleSiteID: Int64 = 123

    func test_product_stock_fields_are_properly_parsed_with_data_envelope() throws {
        // When
        let stock = mapStockItems(from: "product-stock")
        let item = try XCTUnwrap(stock.first)

        // Then
        XCTAssertEqual(item.productID, 2051)
        XCTAssertEqual(item.parentID, 0)
        XCTAssertEqual(item.name, "貴志川線 1日乘車券")
        XCTAssertEqual(item.sku, "")
        XCTAssertEqual(item.productStockStatus, .outOfStock)
        XCTAssertEqual(item.stockQuantity, 0)
        XCTAssertFalse(item.manageStock)
    }

    func test_product_stock_fields_are_properly_parsed_without_data_envelope() throws {
        // When
        let stock = mapStockItems(from: "product-stock-without-data-envelope")
        let item = try XCTUnwrap(stock.first)

        // Then
        XCTAssertEqual(item.productID, 2051)
        XCTAssertEqual(item.parentID, 0)
        XCTAssertEqual(item.name, "貴志川線 1日乘車券")
        XCTAssertEqual(item.sku, "")
        XCTAssertEqual(item.productStockStatus, .outOfStock)
        XCTAssertEqual(item.stockQuantity, 0)
        XCTAssertFalse(item.manageStock)
    }

    func test_product_stock_fields_are_properly_parsed_with_decimal_sku() throws {
        // When
        let stock = mapStockItems(from: "product-stock-decimal-sku")
        let item = try XCTUnwrap(stock.first)

        // Then
        XCTAssertEqual(item.productID, 2051)
        XCTAssertEqual(item.name, "貴志川線 1日乘車券")
        XCTAssertEqual(item.sku, "123")
        XCTAssertEqual(item.productStockStatus, .outOfStock)
        XCTAssertEqual(item.stockQuantity, 0)
        XCTAssertFalse(item.manageStock)
    }

    func test_product_stock_fields_are_properly_parsed_with_parent_managing_stock() throws {
        // When
        let stock = mapStockItems(from: "product-stock-parent-manage-stock")
        let item = try XCTUnwrap(stock.first)

        // Then
        XCTAssertEqual(item.productID, 2051)
        XCTAssertEqual(item.name, "貴志川線 1日乘車券")
        XCTAssertEqual(item.sku, "")
        XCTAssertEqual(item.productStockStatus, .outOfStock)
        XCTAssertEqual(item.stockQuantity, 0)
        XCTAssertTrue(item.manageStock)
    }

    func test_product_stock_fields_are_properly_parsed_with_quantity_in_string() throws {
        // When
        let stock = mapStockItems(from: "product-stock-string-quantity")
        let item = try XCTUnwrap(stock.first)

        // Then
        XCTAssertEqual(item.productID, 2051)
        XCTAssertEqual(item.name, "貴志川線 1日乘車券")
        XCTAssertEqual(item.sku, "")
        XCTAssertEqual(item.productStockStatus, .outOfStock)
        XCTAssertEqual(item.stockQuantity, 12)
        XCTAssertFalse(item.manageStock)
    }
}

private extension ProductStockListMapperTests {
    /// Returns the ProductStockListMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapStockItems(from filename: String) -> [ProductStock] {
        guard let response = Loader.contentsOf(filename) else {
            return []
        }

        return try! ProductStockListMapper(siteID: sampleSiteID).map(response: response)
    }
}
