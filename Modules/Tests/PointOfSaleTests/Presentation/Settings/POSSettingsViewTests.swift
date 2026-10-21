import Testing
@testable import PointOfSale

struct POSSettingsViewTests {
    @Test func trackSelection_when_payments_is_selected_then_tracks_settings_payments_tapped() throws {
        // Given
        let analytics = MockPOSAnalytics()

        // When
        POSSettingsView.SidebarNavigation.payments.trackSelection(with: analytics)

        // Then
        let event = try #require(analytics.events.first)
        #expect(analytics.events.count == 1)
        #expect(event.eventName == "settings_payments_tapped")
    }
}
