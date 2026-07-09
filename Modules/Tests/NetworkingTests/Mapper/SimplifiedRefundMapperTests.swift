import Foundation
import Testing
@testable import Networking
@testable import NetworkingCore

/// SimplifiedRefundMapper Unit Tests
///
struct SimplifiedRefundMapperTests {

    private let sampleSiteID: Int64 = 1234
    private let sampleOrderID: Int64 = 560

    private var mapper: SimplifiedRefundMapper {
        SimplifiedRefundMapper(siteID: sampleSiteID, orderID: sampleOrderID)
    }

    @Test func map_injects_site_and_order_identifiers_and_parses_top_level_fields() throws {
        // Given
        let response = try #require(Loader.contentsOf("simplified-refund"))

        // When
        let refund = try mapper.map(response: response)

        // Then
        #expect(refund.refundID == 3266)
        #expect(refund.siteID == sampleSiteID)
        #expect(refund.orderID == sampleOrderID)
        #expect(refund.amount == "96.00")
        #expect(refund.reason == "Simplified refund")
        #expect(refund.isAutomated == true)
        #expect(refund.dateCreated == DateFormatter.Defaults.dateTimeFormatter.date(from: "2026-06-26T08:20:53"))
    }

    @Test func map_negates_line_values_per_the_v3_storage_contract() throws {
        // Given a v4 response with positive magnitudes (quantity 2, refund_total 20.00, tax 2.00)
        let response = try #require(Loader.contentsOf("simplified-refund"))

        // When
        let refund = try mapper.map(response: response)

        // Then
        let taxedItem = try #require(refund.items.first)
        #expect(taxedItem.itemID == 90)
        #expect(taxedItem.refundedItemID == "50")
        #expect(taxedItem.quantity == -2)
        #expect(taxedItem.subtotal == "-20")
        #expect(taxedItem.totalTax == "-2")
        #expect(taxedItem.total == "-22")

        let tax = try #require(taxedItem.taxes.first)
        #expect(tax.taxID == 7)
        #expect(tax.total == "-2")
    }

    @Test func map_when_refund_tax_is_empty_then_tax_is_zero() throws {
        // Given the second line (refund_total 74.00, no quantity, empty refund_tax)
        let response = try #require(Loader.contentsOf("simplified-refund"))

        // When
        let refund = try mapper.map(response: response)

        // Then
        let untaxedItem = try #require(refund.items.last)
        #expect(untaxedItem.itemID == 91)
        #expect(untaxedItem.refundedItemID == "51")
        #expect(untaxedItem.quantity == 0)
        #expect(untaxedItem.subtotal == "-74")
        #expect(untaxedItem.totalTax == "0")
        #expect(untaxedItem.total == "-74")
        #expect(untaxedItem.taxes.isEmpty)
    }

    @Test func map_puts_all_merged_lines_into_items_and_leaves_typed_lines_empty() throws {
        // Given v4 merges products/fees/shipping into `line_items` with no type discriminator
        let response = try #require(Loader.contentsOf("simplified-refund"))

        // When
        let refund = try mapper.map(response: response)

        // Then
        #expect(refund.items.count == 2)
        #expect(refund.shippingLines?.isEmpty == true)
        #expect(refund.feeLines.isEmpty)
    }
}
