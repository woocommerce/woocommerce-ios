import Foundation
import Testing
import struct Yosemite.POSSimpleProduct
@testable import WooCommerce

struct StockFormatterTests {
    @Test func test_managestock_when_disabled_and_stockStatusKey_not_set_then_returns_empty_stockLabel() async throws {
        // Given
        let manageStockDisabled: Bool = false
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockDisabled)

        // When
        let stockLabel = StockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "")
    }

    @Test func test_managestock_when_disabled_and_stockStatusKey_instock_then_returns_in_stock_stockLabel() async throws {
        // Given
        let manageStockDisabled: Bool = false
        let stockStatusKey: String = "instock"
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockDisabled, stockStatusKey: stockStatusKey)

        // When
        let stockLabel = StockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "In stock")
    }

    @Test func test_managestock_when_disabled_and_stockStatusKey_onbackorder_then_returns_on_backorder_stockLabel() async throws {
        // Given
        let manageStockDisabled: Bool = false
        let stockStatusKey: String = "onbackorder"
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockDisabled, stockStatusKey: stockStatusKey)

        // When
        let stockLabel = StockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "On back order")
    }

    @Test func test_managestock_when_disabled_and_stockStatusKey_outofstock_then_returns_out_of_stock_stockLabel() async throws {
        // Given
        let manageStockEnabled: Bool = false
        let stockStatusKey: String = "outofstock"
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockEnabled,
                                                   stockStatusKey: stockStatusKey)

        // When
        let result = StockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(result == "Out of stock")
    }
}
