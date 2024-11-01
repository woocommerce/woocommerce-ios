import XCTest
@testable import WooCommerce

final class PointOfSaleCardPresentPaymentOnboardingViewModelTests: XCTestCase {
    func test_onDismissTap_is_invoked_when_cancelOnboarding_is_called() throws {
        // Given
        var isDismissTapInvoked = false
        let sut = PointOfSaleCardPresentPaymentOnboardingViewModel(onboardingViewModel: .init(fixedState: .genericError),
            onDismissTap: {
                isDismissTapInvoked = true
            })

        // When
        sut.cancelOnboarding()

        // Then
        XCTAssertTrue(isDismissTapInvoked)
    }

    func test_onboardingURL_is_set_when_onboarding_vm_showURL_is_invoked() throws {
        // Given
        let onboardingViewModel = CardPresentPaymentsOnboardingViewModel(fixedState: .noConnectionError)
        let sut = PointOfSaleCardPresentPaymentOnboardingViewModel(onboardingViewModel: onboardingViewModel, onDismissTap: nil)
        XCTAssertNil(sut.onboardingURL)

        // When
        let url = try XCTUnwrap(URL(string: "https://example.com"))
        onboardingViewModel.showURL?(url)

        // Then
        XCTAssertEqual(sut.onboardingURL, url)
    }

    // MARK: Analytics

    func test_paymentsOnboardingDismissed_event_is_tracked_with_state_when_cancelOnboarding_is_invoked() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = PointOfSaleCardPresentPaymentOnboardingViewModel(onboardingViewModel: .init(fixedState: .noConnectionError),
                                                                   onDismissTap: nil,
                                                                   analytics: analytics)

        // When
        sut.cancelOnboarding()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "pos_payments_onboarding_dismissed" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties.first(where: { $0.keys.contains("onboarding_state") }))
        XCTAssertEqual(eventProperties["onboarding_state"] as? String, "no_connection_error")
    }

    func test_pointOfSalePaymentsOnboardingShown_event_is_tracked_when_trackOnboardingShown_is_invoked() throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        let sut = PointOfSaleCardPresentPaymentOnboardingViewModel(onboardingViewModel: .init(fixedState: .noConnectionError),
                                                                   onDismissTap: nil,
                                                                   analytics: analytics)

        // When
        sut.trackOnboardingShown()

        // Then
        XCTAssertNotNil(analyticsProvider.receivedEvents.first(where: { $0 == "pos_payments_onboarding_shown" }))
    }
}
