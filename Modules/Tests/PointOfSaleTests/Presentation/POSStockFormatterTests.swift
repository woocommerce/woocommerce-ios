import Foundation
import Testing
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariation
@testable import PointOfSale

struct POSStockFormatterTests {
    @Test func test_when_managestock_disabled_and_stockStatusKey_not_set_then_returns_empty_stockLabel() async throws {
        // Given
        let manageStockDisabled: Bool = false
        let product = POSSimpleProduct.fake().copy(manageStock: manageStockDisabled)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel.isEmpty)
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

    @Test func test_when_pointOfSaleStockQuantity_is_available_then_returns_pos_stock_quantity_label() async throws {
        // Given
        let product = POSSimpleProduct.fake().copy(manageStock: false,
                                                   stockQuantity: 99,
                                                   stockStatusKey: "outofstock",
                                                   pointOfSaleStockQuantity: 4)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "4 in stock")
    }

    @Test func test_when_pointOfSaleStockQuantity_is_zero_then_returns_out_of_stock_label() async throws {
        // Given
        let product = POSSimpleProduct.fake().copy(manageStock: true,
                                                   stockQuantity: 99,
                                                   stockStatusKey: "instock",
                                                   pointOfSaleStockQuantity: 0)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "Out of stock")
    }

    @Test func test_when_pointOfSaleStockQuantity_is_not_available_then_falls_back_to_core_stock_quantity() async throws {
        // Given
        let product = POSSimpleProduct.fake().copy(manageStock: true,
                                                   stockQuantity: 0,
                                                   stockStatusKey: "instock",
                                                   pointOfSaleStockQuantity: nil)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: product)

        // Then
        #expect(stockLabel == "Out of stock")
    }

    @Test func test_when_managestock_enabled_and_stockQuantity_is_positive_then_returns_number_in_stock_stockLabel() async throws {
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

    @Test func test_when_variation_pointOfSaleStockQuantity_is_available_then_returns_pos_stock_quantity_label() async throws {
        // Given
        let variation = POSVariation(id: .init(underlyingType: .variation, itemID: 123),
                                     name: "Variation",
                                     formattedPrice: "$10.00",
                                     price: "10.00",
                                     productID: 456,
                                     variationID: 123,
                                     parentProductName: "Product",
                                     manageStock: false,
                                     stockQuantity: 99,
                                     stockStatusKey: "outofstock",
                                     pointOfSaleStockQuantity: 4)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: variation)

        // Then
        #expect(stockLabel == "4 in stock")
    }

    @Test func test_when_variation_pointOfSaleStockQuantity_is_not_available_then_falls_back_to_core_stock_quantity() async throws {
        // Given
        let variation = POSVariation(id: .init(underlyingType: .variation, itemID: 123),
                                     name: "Variation",
                                     formattedPrice: "$10.00",
                                     price: "10.00",
                                     productID: 456,
                                     variationID: 123,
                                     parentProductName: "Product",
                                     manageStock: true,
                                     stockQuantity: 5,
                                     stockStatusKey: "instock",
                                     pointOfSaleStockQuantity: nil)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: variation)

        // Then
        #expect(stockLabel == "5 in stock")
    }

    @Test func test_when_variation_has_no_own_pos_or_core_stock_then_uses_parent_pos_stock_quantity() async throws {
        // Given
        let variation = POSVariation(id: .init(underlyingType: .variation, itemID: 123),
                                     name: "Variation",
                                     formattedPrice: "$10.00",
                                     price: "10.00",
                                     productID: 456,
                                     variationID: 123,
                                     parentProductName: "Product",
                                     manageStock: false,
                                     stockQuantity: nil,
                                     stockStatusKey: "outofstock",
                                     pointOfSaleStockQuantity: nil,
                                     parentManageStock: true,
                                     parentStockQuantity: 8,
                                     parentStockStatusKey: "instock",
                                     parentPointOfSaleStockQuantity: 6)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: variation)

        // Then
        #expect(stockLabel == "6 in stock")
    }

    @Test func test_when_variation_has_no_own_stock_or_parent_pos_stock_then_uses_parent_core_stock_quantity() async throws {
        // Given
        let variation = POSVariation(id: .init(underlyingType: .variation, itemID: 123),
                                     name: "Variation",
                                     formattedPrice: "$10.00",
                                     price: "10.00",
                                     productID: 456,
                                     variationID: 123,
                                     parentProductName: "Product",
                                     manageStock: false,
                                     stockQuantity: nil,
                                     stockStatusKey: "outofstock",
                                     pointOfSaleStockQuantity: nil,
                                     parentManageStock: true,
                                     parentStockQuantity: 8,
                                     parentStockStatusKey: "instock",
                                     parentPointOfSaleStockQuantity: nil)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: variation)

        // Then
        #expect(stockLabel == "8 in stock")
    }

    @Test func test_when_variation_has_own_pos_stock_then_it_overrides_parent_stock() async throws {
        // Given
        let variation = POSVariation(id: .init(underlyingType: .variation, itemID: 123),
                                     name: "Variation",
                                     formattedPrice: "$10.00",
                                     price: "10.00",
                                     productID: 456,
                                     variationID: 123,
                                     parentProductName: "Product",
                                     manageStock: false,
                                     stockQuantity: nil,
                                     stockStatusKey: "outofstock",
                                     pointOfSaleStockQuantity: 2,
                                     parentManageStock: true,
                                     parentStockQuantity: 8,
                                     parentStockStatusKey: "instock",
                                     parentPointOfSaleStockQuantity: 6)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: variation)

        // Then
        #expect(stockLabel == "2 in stock")
    }

    @Test func test_when_variation_has_own_core_stock_then_it_overrides_parent_stock() async throws {
        // Given
        let variation = POSVariation(id: .init(underlyingType: .variation, itemID: 123),
                                     name: "Variation",
                                     formattedPrice: "$10.00",
                                     price: "10.00",
                                     productID: 456,
                                     variationID: 123,
                                     parentProductName: "Product",
                                     manageStock: true,
                                     stockQuantity: 3,
                                     stockStatusKey: "instock",
                                     pointOfSaleStockQuantity: nil,
                                     parentManageStock: true,
                                     parentStockQuantity: 8,
                                     parentStockStatusKey: "instock",
                                     parentPointOfSaleStockQuantity: 6)

        // When
        let stockLabel = POSStockFormatter.stockStatusLabel(for: variation)

        // Then
        #expect(stockLabel == "3 in stock")
    }
}
