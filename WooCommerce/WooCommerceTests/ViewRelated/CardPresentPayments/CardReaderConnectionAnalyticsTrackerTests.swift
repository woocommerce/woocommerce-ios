import Testing
import Yosemite
@testable import WooCommerce

@MainActor struct CardReaderConnectionAnalyticsTrackerTests {

    @Test func cardReaderLocationMissingTapped_tracks_card_reader_location_missing_tapped_event() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = CardReaderConnectionAnalyticsTracker(
            configuration: CardPresentPaymentsConfiguration(country: .US),
            siteID: 123,
            connectionType: .userInitiated,
            stores: MockStoresManager(sessionManager: .testingInstance),
            analytics: analytics)

        // When
        sut.cardReaderLocationMissingTapped()

        // Then
        let index = try #require(analyticsProvider.receivedEvents.firstIndex(of: "card_reader_location_missing_tapped"))
        let properties = analyticsProvider.receivedProperties[index]
        #expect(properties["country"] as? String == "US")
    }
}
