import Foundation
import Testing
@testable import WooCommerce
import Yosemite
import protocol WooFoundation.Analytics

@MainActor
struct InPersonPaymentsStripeAccountOverdueViewModelTests {
    private let sessionManager: SessionManager
    private let stores: MockStoresManager
    private let analyticsProvider: MockAnalyticsProvider
    private let analytics: Analytics
    private let sut: InPersonPaymentsStripeAccountOverdueViewModel

    init() {
        sessionManager = .makeForTesting()
        sessionManager.defaultSite = Site.fake().copy(adminURL: "https://example.com/wp-admin/")
        stores = MockStoresManager(sessionManager: sessionManager)
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = InPersonPaymentsStripeAccountOverdueViewModel(plugin: .wcPay,
                                                            analyticReason: "account_overdue_requirements",
                                                            stores: stores,
                                                            analytics: analytics,
                                                            cardPresentConfiguration: CardPresentPaymentsConfiguration(country: .US),
                                                            onRefresh: {},
                                                            onSkip: {})
    }

    @Test func resolveNowTapped_presents_the_plugin_setup_URL_from_the_default_site() async throws {
        // When
        sut.resolveNowTapped()

        // Then
        #expect(sut.presentedSetupURL == URL(string: "https://example.com/wp-admin/admin.php?page=wc-admin&path=%2Fpayments%2Fconnect"))
    }

    @Test func resolveNowTapped_when_there_is_no_default_site_then_presents_no_URL() async throws {
        // Given
        sessionManager.defaultSite = nil

        // When
        sut.resolveNowTapped()

        // Then
        #expect(sut.presentedSetupURL == nil)
    }

    @Test func resolveNowTapped_tracks_cta_failed_event_with_stripe_account_setup_tapped_reason() async throws {
        // When
        sut.resolveNowTapped()

        // Then
        let eventIndex = try #require(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.cardPresentOnboardingCtaFailed.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        #expect(properties["reason"] as? String == "stripe_account_setup_tapped")
        #expect(properties["country"] as? String == "US")
        #expect(properties["plugin_slug"] as? String == CardPresentPaymentsPlugin.wcPay.gatewayID)
    }

    @Test func resolveNowTapped_does_not_track_cta_tapped_event_as_the_button_view_model_owns_it() async throws {
        // When
        sut.resolveNowTapped()

        // Then
        #expect(!analyticsProvider.receivedEvents.contains(WooAnalyticsStat.cardPresentOnboardingCtaTapped.rawValue))
    }
}
