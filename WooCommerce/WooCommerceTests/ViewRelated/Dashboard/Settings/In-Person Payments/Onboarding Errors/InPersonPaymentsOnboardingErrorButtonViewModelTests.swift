import Testing
import WooFoundationCore
@testable import WooCommerce

struct InPersonPaymentsOnboardingErrorButtonViewModelTests {
    @Test(arguments: [true, false])
    func test_action_when_tracking_is_configured_then_always_calls_action_and_tracks_only_when_enabled(trackTap: Bool) {
        // Given
        let provider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: provider)
        var didCallAction = false
        let viewModel = InPersonPaymentsOnboardingErrorButtonViewModel(
            text: "Action",
            analyticReason: "wcpay_not_installed",
            cardPresentConfiguration: .init(country: .US),
            plugin: .wcPay,
            trackTap: trackTap,
            analytics: analytics,
            action: { didCallAction = true }
        )

        // When
        viewModel.action()

        // Then
        #expect(didCallAction)
        let expectedEvents = trackTap ? [WooAnalyticsStat.cardPresentOnboardingCtaTapped.rawValue] : []
        #expect(provider.receivedEvents == expectedEvents)
    }

    @Test func test_action_when_tracking_uses_default_then_tracks_tap_and_calls_action() {
        // Given
        let provider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: provider)
        var didCallAction = false
        let viewModel = InPersonPaymentsOnboardingErrorButtonViewModel(
            text: "Action",
            analyticReason: "generic_error",
            cardPresentConfiguration: .init(country: .US),
            plugin: nil,
            analytics: analytics,
            action: { didCallAction = true }
        )

        // When
        viewModel.action()

        // Then
        #expect(didCallAction)
        #expect(provider.receivedEvents == [WooAnalyticsStat.cardPresentOnboardingCtaTapped.rawValue])
    }
}
