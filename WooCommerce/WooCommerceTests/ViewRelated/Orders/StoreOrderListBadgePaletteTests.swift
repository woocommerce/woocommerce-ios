import SwiftUI
import Testing
import Yosemite
@testable import WooCommerce

@Suite struct StoreOrderListBadgePaletteTests {
    @Test(arguments: [
        OrderStatusEnum.processing,
        .failed,
        .completed,
        .onHold,
        .pending,
        .cancelled,
        .refunded,
        .custom("custom")
    ])
    func test_status_background_when_status_changes_then_matches_last_order_dashboard_card(status: OrderStatusEnum) {
        #expect(StoreOrderListBadgePalette.statusBackground(for: status) == Color(uiColor: status.backgroundColor))
    }
}
