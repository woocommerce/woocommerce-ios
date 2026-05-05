import Testing
import protocol WooFoundation.Analytics
@testable import WooCommerce

struct AIAssistantAnalyticsAdaptorTests {

    @Test
    func test_track_when_called_then_forwards_event_name_and_properties_to_analytics() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = AIAssistantAnalyticsAdaptor(analytics: analytics)

        // When
        sut.track(event: "ai_assistant_message_sent", properties: ["source": "dashboard"])

        // Then
        #expect(analyticsProvider.receivedEvents == ["ai_assistant_message_sent"])
        #expect(analyticsProvider.receivedProperties.last?["source"] as? String == "dashboard")
    }

    @Test
    func test_track_when_properties_empty_then_forwards_no_properties() {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = AIAssistantAnalyticsAdaptor(analytics: analytics)

        // When
        sut.track(event: "ai_assistant_opened", properties: [:])

        // Then
        #expect(analyticsProvider.receivedEvents == ["ai_assistant_opened"])
        #expect(analyticsProvider.receivedProperties.isEmpty)
    }
}
