import Testing
import struct WooFoundation.WooAnalyticsEvent
import enum WooFoundationCore.WooAnalyticsStat
@testable import PointOfSale

struct WooAnalyticsEventPointOfSaleTests {
    @Test func checkoutTapped_includes_cart_counts() {
        // When
        let event = WooAnalyticsEvent.PointOfSale.checkoutTapped(
            purchasableItemsInCart: 2,
            couponsInCart: 1
        )

        // Then
        #expect(event.statName == WooAnalyticsStat.pointOfSaleCheckoutTapped)
        #expect(event.properties["products_in_cart"] as? Int == 2)
        #expect(event.properties["coupons_in_cart"] as? Int == 1)
        #expect(event.properties.keys.contains("pos_layout") == false)
    }
}
