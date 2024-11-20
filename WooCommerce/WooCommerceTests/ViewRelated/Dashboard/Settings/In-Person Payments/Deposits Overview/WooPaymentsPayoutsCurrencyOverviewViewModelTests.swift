import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class WooPaymentsPayoutsCurrencyOverviewViewModelTests: XCTestCase {

    var sut: WooPaymentsPayoutsCurrencyOverviewViewModel!
    var analyticsProvider: MockAnalyticsProvider!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = WooPaymentsPayoutsCurrencyOverviewViewModel(overview: .fake(), analytics: analytics)
    }

    func test_when_expand_is_tapped_analytic_event_is_tracked() {
        // Given
        let expanded = true

        // When
        sut.expandTapped(expanded: expanded)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuPayoutSummaryExpanded.rawValue))
    }

    func test_when_collapse_is_tapped_analytic_event_is_not_tracked() {
        // Given
        let collapse = false

        // When
        sut.expandTapped(expanded: collapse)

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuPayoutSummaryExpanded.rawValue))
    }

    func test_when_learn_more_is_tapped_analytic_event_is_tracked() {
        // Given

        // When
        sut.learnMoreTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuPayoutSummaryLearnMoreTapped.rawValue))
    }

    func test_when_learn_more_is_tapped_payout_schedule_info_webview_is_shown() {
        // Given

        // When
        sut.learnMoreTapped()

        // Then
        assertEqual(WooConstants.URLs.wooPaymentsPayoutSchedule.asURL(), sut.showWebviewURL)
    }

    func test_when_currency_matches_site_settings_amounts_formatted_using_woo_currency_formatter() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let overview = WooPaymentsPayoutsOverviewByCurrency.fake().copy(currency: .USD, availableBalance: .init(string: "12.35"))

        // When
        sut = WooPaymentsPayoutsCurrencyOverviewViewModel(overview: overview, locale: Locale(identifier: "en-ca"))

        // Then
        assertEqual(sut.availableBalance, "$12.35")
    }

    func test_when_currency_doesnt_match_site_settings_amounts_formatted_using_system_locale_currency_formatter() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let overview = WooPaymentsPayoutsOverviewByCurrency.fake().copy(currency: .CAD, availableBalance: .init(string: "12.35"))

        // When
        sut = WooPaymentsPayoutsCurrencyOverviewViewModel(overview: overview, locale: Locale(identifier: "en-us"))

        // Then
        assertEqual(sut.availableBalance, "CA$12.35")
    }

}
