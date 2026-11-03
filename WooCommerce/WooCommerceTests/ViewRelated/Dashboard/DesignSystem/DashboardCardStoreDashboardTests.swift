import Testing
@testable import WooCommerce
import struct Yosemite.DashboardCard

struct DashboardCardStoreDashboardTests {
    @Test func test_cards_for_store_dashboard_when_share_store_is_visible_then_hides_new_cards_notice() {
        // Given
        let cards = [
            DashboardCard(type: .performance, availability: .show, enabled: true),
            .newCardsNoticeCard,
            .shareStoreCard
        ]

        // When
        let result = cards.cardsForStoreDashboard

        // Then
        #expect(result.map(\.type) == [.performance, .shareStore])
    }

    @Test func test_cards_for_store_dashboard_when_share_store_is_not_visible_then_keeps_new_cards_notice() {
        // Given
        let cards = [
            DashboardCard(type: .performance, availability: .show, enabled: true),
            .newCardsNoticeCard
        ]

        // When
        let result = cards.cardsForStoreDashboard

        // Then
        #expect(result.map(\.type) == [.performance, .newCardsNotice])
    }
}
