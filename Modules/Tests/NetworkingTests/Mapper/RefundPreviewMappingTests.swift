import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

/// RefundPreview mapping tests.
///
struct RefundPreviewMappingTests {

    private let mapper = SingleItemMapper<RefundPreview>(siteID: 1234)

    @Test func map_parses_all_totals_and_breakdown_sections() throws {
        // Given
        let response = try #require(Loader.contentsOf("refund-preview"))

        // When
        let preview = try mapper.map(response: response)

        // Then
        #expect(preview.subtotal == Decimal(string: "27.00"))
        #expect(preview.tax == Decimal(string: "2.70"))
        #expect(preview.total == Decimal(string: "29.70"))
        #expect(preview.maxRefundable == Decimal(string: "50.00"))

        let products = preview.breakdown.products
        #expect(products.subtotal == Decimal(string: "20.00"))
        #expect(products.tax == Decimal(string: "2.00"))
        #expect(products.total == Decimal(string: "22.00"))

        let productItem = try #require(products.items.first)
        #expect(productItem.id == 1)
        #expect(productItem.name == "Product")
        #expect(productItem.quantity == 2)
        #expect(productItem.subtotal == Decimal(string: "20.00"))
        #expect(productItem.tax == Decimal(string: "2.00"))
        #expect(productItem.total == Decimal(string: "22.00"))
        #expect(productItem.productID == 10)

        let fees = preview.breakdown.fees
        #expect(fees.subtotal == Decimal(string: "4.00"))
        #expect(fees.tax == Decimal(string: "0.40"))
        #expect(fees.total == Decimal(string: "4.40"))

        let feeItem = try #require(fees.items.first)
        #expect(feeItem.id == 3)
        #expect(feeItem.name == "Custom amount")
        #expect(feeItem.quantity == nil)
        #expect(feeItem.subtotal == Decimal(string: "4.00"))
        #expect(feeItem.tax == Decimal(string: "0.40"))
        #expect(feeItem.total == Decimal(string: "4.40"))
        #expect(feeItem.productID == nil)
    }

    @Test func map_when_item_fields_are_null_then_maps_to_nil() throws {
        // Given a shipping item with null quantity and product_id
        let response = try #require(Loader.contentsOf("refund-preview"))

        // When
        let preview = try mapper.map(response: response)

        // Then
        let shippingItem = try #require(preview.breakdown.shipping.items.first)
        #expect(shippingItem.quantity == nil)
        #expect(shippingItem.productID == nil)
        #expect(shippingItem.total == Decimal(string: "3.30"))
    }

    @Test func map_when_a_section_is_null_then_maps_to_an_empty_section() throws {
        // Given a response with null breakdown sections
        let response = try #require(Loader.contentsOf("refund-preview-nulls"))

        // When
        let preview = try mapper.map(response: response)

        // Then
        #expect(preview.breakdown.fees.items.isEmpty)
        #expect(preview.breakdown.fees.subtotal == .zero)
        #expect(preview.breakdown.fees.tax == .zero)
        #expect(preview.breakdown.fees.total == .zero)
    }

    @Test func map_when_all_monetary_values_are_null_then_maps_to_zeros() throws {
        // Given
        let response = try #require(Loader.contentsOf("refund-preview-nulls"))

        // When
        let preview = try mapper.map(response: response)

        // Then
        #expect(preview.subtotal == .zero)
        #expect(preview.tax == .zero)
        #expect(preview.total == .zero)
        #expect(preview.maxRefundable == .zero)
        #expect(preview.breakdown.products.items.isEmpty)
        #expect(preview.breakdown.shipping.items.isEmpty)
        #expect(preview.breakdown.fees.items.isEmpty)
    }
}
