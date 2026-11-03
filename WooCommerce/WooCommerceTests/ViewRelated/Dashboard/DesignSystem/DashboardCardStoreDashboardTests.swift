import Testing
@testable import WooCommerce
import struct Yosemite.DashboardCard

struct DashboardCardStoreDashboardTests {
    @Test func cards_for_store_dashboard_when_share_store_is_visible_then_hides_new_cards_notice() {
        let cards = [
            DashboardCard(type: .performance, availability: .show, enabled: true),
            .newCardsNoticeCard,
            .shareStoreCard
        ]

        let result = cards.cardsForStoreDashboard

        #expect(result.map(\.type) == [.performance, .shareStore])
    }

    @Test func cards_for_store_dashboard_when_share_store_is_not_visible_then_keeps_new_cards_notice() {
        let cards = [
            DashboardCard(type: .performance, availability: .show, enabled: true),
            .newCardsNoticeCard
        ]

        let result = cards.cardsForStoreDashboard

        #expect(result.map(\.type) == [.performance, .newCardsNotice])
    }
}
