import Testing
import struct WooFoundation.WooAnalyticsEvent
@testable import PointOfSale

struct POSCustomAmountAnalyticsEventTests {
    @Test func test_itemRemovedFromCart_when_custom_amount_is_removed_then_keeps_cart_event_contract() {
        // Given, When
        let event = WooAnalyticsEvent.PointOfSale.itemRemovedFromCart(sourceView: .cart, itemType: .customAmount)

        // Then
        #expect(event.statName.rawValue == "item_removed_from_cart")
        #expect(event.properties["source"] as? String == "cart")
        #expect(event.properties["item_type"] as? String == "custom_amount")
        #expect(event.properties.count == 2)
    }
}
