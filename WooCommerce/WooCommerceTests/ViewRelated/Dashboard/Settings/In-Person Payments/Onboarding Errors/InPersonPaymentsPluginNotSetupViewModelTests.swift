import Foundation
import Testing
@testable import WooCommerce
import Yosemite
import protocol WooFoundation.Analytics

struct InPersonPaymentsPluginNotSetupViewModelTests {
    private let stores: MockStoresManager
    private let analyticsProvider: MockAnalyticsProvider
    private let analytics: Analytics
    private let sut: InPersonPaymentsPluginNotSetupViewModel

    init() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        stores.sessionManager.defaultSite = Site.fake().copy(adminURL: "https://example.com/wp-admin/")
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = InPersonPaymentsPluginNotSetupViewModel(plugin: .wcPay,
                                                      analyticReason: "wcpay_not_setup",
                                                      stores: stores,
                                                      analytics: analytics,
                                                      cardPresentConfiguration: CardPresentPaymentsConfiguration(country: .US),
                                                      onRefresh: {})
    }

    @Test func setupButtonTapped_presents_the_plugin_setup_URL_from_the_default_site() async throws {
        // When
        sut.setupButtonTapped()

        // Then
        #expect(sut.presentedSetupURL == URL(string: "https://example.com/wp-admin/admin.php?page=wc-admin&path=%2Fpayments%2Fconnect"))
    }

    @Test func setupButtonTapped_when_there_is_no_default_site_then_presents_no_URL() async throws {
        // Given
        stores.sessionManager.defaultSite = nil

        // When
        sut.setupButtonTapped()

        // Then
        #expect(sut.presentedSetupURL == nil)
    }

    @Test func setupButtonTapped_tracks_cta_tapped_event_with_reason_and_gateway() async throws {
        // When
        sut.setupButtonTapped()

        // Then
        let eventIndex = try #require(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.cardPresentOnboardingCtaTapped.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        #expect(properties["reason"] as? String == "wcpay_not_setup")
        #expect(properties["country"] as? String == "US")
        #expect(properties["plugin_slug"] as? String == CardPresentPaymentsPlugin.wcPay.gatewayID)
    }

    @Test func setupButtonTapped_tracks_cta_failed_event_with_plugin_setup_tapped_reason() async throws {
        // When
        sut.setupButtonTapped()

        // Then
        let eventIndex = try #require(analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.cardPresentOnboardingCtaFailed.rawValue))
        let properties = analyticsProvider.receivedProperties[eventIndex]
        #expect(properties["reason"] as? String == "plugin_setup_tapped")
    }
}
