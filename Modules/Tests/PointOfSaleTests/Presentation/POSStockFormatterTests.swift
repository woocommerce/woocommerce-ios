import Foundation
import Testing
import struct Yosemite.POSSimpleProduct
@testable import PointOfSale

struct POSStockFormatterTests {
    @Test func test_when_managestock_disabled_and_stockStatusKey_not_set_then_returns_empty_stockLabel() async throws {
        // Given
        let manageStockDisabled: Bool = false
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockDisabled)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "")
    }

    @Test func test_when_managestock_disabled_and_stockStatusKey_instock_then_returns_in_stock_stockLabel() async throws {
        // Given
        let manageStockDisabled: Bool = false
        let stockStatusKey: String = "instock"
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockDisabled, stockStatusKey: stockStatusKey)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "In stock")
    }

    @Test func test_when_managestock_disabled_and_stockStatusKey_onbackorder_then_returns_on_backorder_stockLabel() async throws {
        // Given
        let manageStockDisabled: Bool = false
        let stockStatusKey: String = "onbackorder"
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockDisabled, stockStatusKey: stockStatusKey)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "On back order")
    }

    @Test func test_when_managestock_disabled_and_stockStatusKey_outofstock_then_returns_out_of_stock_stockLabel() async throws {
        // Given
        let manageStockEnabled: Bool = false
        let stockStatusKey: String = "outofstock"
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockEnabled,
                                                   stockStatusKey: stockStatusKey)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "Out of stock")
    }

    @Test func test_when_managestock_enabled_and_stockQuantity_not_set_then_returns_productStockStatus_stockLabel() async throws {
        // Given
        let manageStockEnabled: Bool = true
        let stockStatusKey: String = "instock"
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockEnabled,
                                                   stockStatusKey: stockStatusKey)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "In stock")
    }

    @Test func test_when_managestock_enabled_and_stockQuantity_less_than_zero_then_returns_out_of_stock_stockLabel() async throws {
        // Given
        let manageStockEnabled: Bool = true
        let stockQuantity: Decimal = -3
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockEnabled,
                                                   stockQuantity: stockQuantity)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "Out of stock")
    }

    @Test func test_when_managestock_enabled_and_stockQuantity_is_zero_then_returns_out_of_stock_stockLabel() async throws {
        // Given
        let manageStockEnabled: Bool = true
        let stockQuantity: Decimal = 0
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockEnabled,
                                                   stockQuantity: stockQuantity)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "Out of stock")
    }

    // Disabled temporarily due to failure to code freeze 22.5
    // Context: p1748609128918879?thread_ts=1748592083.887729&cid=CC7L49W13-slack-CC7L49W13
    @Test(.disabled()) func test_when_managestock_enabled_and_stockQuantity_is_positive_then_returns_number_in_stock_stockLabel() async throws {
        // Given
        let manageStockEnabled: Bool = true
        let stockQuantity: Decimal = 5
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockEnabled,
                                                   stockQuantity: stockQuantity)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "5 in stock")
    }
}
