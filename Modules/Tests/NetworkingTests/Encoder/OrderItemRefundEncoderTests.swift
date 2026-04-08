import Testing
import Foundation
@testable import Networking
@testable import NetworkingCore

struct OrderItemRefundEncoderTests {

    // MARK: - Default Values

    @Test func init_with_only_required_fields_then_defaults_are_set_correctly() {
        // When
        let item = OrderItemRefund(
            itemID: 42,
            quantity: 2,
            taxes: [],
            total: "10.00"
        )

        // Then
        #expect(item.itemID == 42)
        #expect(item.quantity == 2)
        #expect(item.total == "10.00")
        #expect(item.taxes == [])

        // Defaulted fields
        #expect(item.name.isEmpty == true)
        #expect(item.productID == 0)
        #expect(item.variationID == 0)
        #expect(item.refundedItemID == nil)
        #expect(item.price == .zero)
        #expect(item.sku == nil)
        #expect(item.subtotal.isEmpty == true)
        #expect(item.subtotalTax.isEmpty == true)
        #expect(item.taxClass.isEmpty == true)
        #expect(item.totalTax.isEmpty == true)
    }

    @Test func init_with_explicit_values_then_overrides_defaults() {
        // When
        let item = OrderItemRefund(
            itemID: 1,
            name: "Widget",
            productID: 99,
            variationID: 5,
            refundedItemID: "42",
            quantity: 3,
            price: NSDecimalNumber(string: "15.50"),
            sku: "WDG-001",
            subtotal: "46.50",
            subtotalTax: "4.65",
            taxClass: "standard",
            taxes: [],
            total: "46.50",
            totalTax: "4.65"
        )

        // Then
        #expect(item.name == "Widget")
        #expect(item.productID == 99)
        #expect(item.variationID == 5)
        #expect(item.refundedItemID == "42")
        #expect(item.price == NSDecimalNumber(string: "15.50"))
        #expect(item.sku == "WDG-001")
        #expect(item.subtotal == "46.50")
        #expect(item.subtotalTax == "4.65")
        #expect(item.taxClass == "standard")
        #expect(item.totalTax == "4.65")
    }

    // MARK: - Encoding

    @Test func encode_then_only_encodes_quantity_total_and_taxes() throws {
        // Given
        let item = OrderItemRefund(
            itemID: 42,
            name: "Should not be encoded",
            productID: 99,
            quantity: 2,
            taxes: [OrderItemTaxRefund(taxID: 5, subtotal: "", total: "1.50")],
            total: "20.00"
        )

        // When
        let data = try JSONEncoder().encode(item)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // Then — only the 3 encoded fields should be present
        #expect(json.keys.count == 3)
        #expect(json["qty"] as? Int == 2)
        #expect(json["refund_total"] as? String == "20.00")
        #expect(json["refund_tax"] != nil)

        // Verify non-encoded fields are absent
        #expect(json["id"] == nil)
        #expect(json["name"] == nil)
        #expect(json["product_id"] == nil)
        #expect(json["variation_id"] == nil)
        #expect(json["price"] == nil)
        #expect(json["sku"] == nil)
        #expect(json["subtotal"] == nil)
        #expect(json["subtotal_tax"] == nil)
        #expect(json["tax_class"] == nil)
        #expect(json["total_tax"] == nil)
    }

    @Test func encode_taxes_then_formats_as_dictionary() throws {
        // Given
        let item = OrderItemRefund(
            itemID: 1,
            quantity: 1,
            taxes: [
                OrderItemTaxRefund(taxID: 10, subtotal: "", total: "1.99"),
                OrderItemTaxRefund(taxID: 20, subtotal: "", total: "0.50")
            ],
            total: "15.00"
        )

        // When
        let data = try JSONEncoder().encode(item)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let taxDict = try #require(json["refund_tax"] as? [String: String])

        // Then — taxes encoded as { "tax_id": "total" } dictionary
        #expect(taxDict["10"] == "1.99")
        #expect(taxDict["20"] == "0.50")
    }
}
