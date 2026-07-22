import Foundation
import Testing
@testable import WooCommerce
import Yosemite
import protocol WooFoundation.Analytics

struct InPersonPaymentsOnboardingErrorButtonViewModelTests {

    @Test func action_when_invoked_then_tracks_cta_tapped_event_with_reason_and_gateway() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics: Analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = InPersonPaymentsOnboardingErrorButtonViewModel(
            text: "Refresh",
            analyticReason: "account_pending_requirements",
            cardPresentConfiguration: CardPresentPaymentsConfiguration(country: .US),
            plugin: .wcPay,
            analytics: analytics,
            action: {})

        // When
        sut.action()

        // Then
        let eventIndex = try #require(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.cardPresentOnboardingCtaTapped.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        #expect(properties["reason"] as? String == "account_pending_requirements")
        #expect(properties["country"] as? String == "US")
        #expect(properties["plugin_slug"] as? String == CardPresentPaymentsPlugin.wcPay.gatewayID)
    }

    @Test func action_when_invoked_then_calls_the_wrapped_action_after_tracking() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics: Analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        var actionCalled = false
        let sut = InPersonPaymentsOnboardingErrorButtonViewModel(
            text: "Refresh",
            analyticReason: "reason",
            cardPresentConfiguration: CardPresentPaymentsConfiguration(country: .US),
            plugin: nil,
            analytics: analytics,
            action: { actionCalled = true })

        // When
        sut.action()

        // Then
        #expect(actionCalled)
        #expect(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardPresentOnboardingCtaTapped.rawValue))
    }
}
