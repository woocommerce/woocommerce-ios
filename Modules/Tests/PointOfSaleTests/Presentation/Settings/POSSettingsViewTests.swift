import Testing
@testable import PointOfSale

struct POSSettingsViewTests {
    @Test func categories_are_ordered_with_payments_after_hardware_and_before_product_catalog() {
        // When
        let categories = POSSettingsView.SidebarNavigation.allCases

        // Then
        #expect(categories == [.store, .hardware, .payments, .localCatalog, .staff, .help])
    }

    @Test func trackSelection_when_payments_is_selected_then_tracks_payments_tapped() throws {
        // Given
        let analytics = MockPOSAnalytics()

        // When
        POSSettingsView.SidebarNavigation.payments.trackSelection(with: analytics)

        // Then
        let event = try #require(analytics.events.first)
        #expect(analytics.events.count == 1)
        #expect(event.eventName == "payments_tapped")
    }
}
