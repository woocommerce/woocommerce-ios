import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class WooPaymentsDepositsCurrencyOverviewViewModelTests: XCTestCase {

    var sut: WooPaymentsDepositsCurrencyOverviewViewModel!
    var analyticsProvider: MockAnalyticsProvider!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = WooPaymentsDepositsCurrencyOverviewViewModel(overview: .fake(), analytics: analytics)
    }

    func test_when_expand_is_tapped_analytic_event_is_tracked() {
        // Given
        let expanded = true

        // When
        sut.expandTapped(expanded: expanded)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuDepositSummaryExpanded.rawValue))
    }

    func test_when_collapse_is_tapped_analytic_event_is_not_tracked() {
        // Given
        let collapse = false

        // When
        sut.expandTapped(expanded: collapse)

        // Then
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuDepositSummaryExpanded.rawValue))
    }

    func test_when_learn_more_is_tapped_analytic_event_is_tracked() {
        // Given

        // When
        sut.learnMoreTapped()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuDepositSummaryLearnMoreTapped.rawValue))
    }

    func test_when_learn_more_is_tapped_deposit_schedule_info_webview_is_shown() {
        // Given

        // When
        sut.learnMoreTapped()

        // Then
        assertEqual(WooConstants.URLs.wooPaymentsDepositSchedule.asURL(), sut.showWebviewURL)
    }

    func test_when_currency_matches_site_settings_amounts_formatted_using_woo_currency_formatter() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .left,
                                                thousandSeparator: ",",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 2)
        let overview = WooPaymentsDepositsOverviewByCurrency.fake().copy(currency: .USD, availableBalance: .init(string: "12.35"))

        // When
        sut = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overview, locale: Locale(identifier: "en-ca"))

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
        let overview = WooPaymentsDepositsOverviewByCurrency.fake().copy(currency: .CAD, availableBalance: .init(string: "12.35"))

        // When
        sut = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overview, locale: Locale(identifier: "en-us"))

        // Then
        assertEqual(sut.availableBalance, "CA$12.35")
    }

    func test_when_calculateNextScheduledDeposit_is_daily_then_next_expected_scheduled_date_is_a_day_after() {
        // Given
        let overview = WooPaymentsDepositsOverviewByCurrency.fake().copy(depositInterval: .daily)
        let currentDate = DateComponents(year: 2024, month: 1, day: 8)
        guard let date = Calendar.current.date(from: currentDate) else {
            return XCTFail("Unable to construct date.")
        }
        let nextExpectedScheduledDepositDate = "Jan 9, 2024"

        // When
        sut = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overview, date: date)

        // Then
        assertEqual(nextExpectedScheduledDepositDate, sut.nextScheduledDeposit)
    }

    func test_when_calculateNextScheduledDeposit_is_weekly_then_next_expected_deposit_scheduled_date_is_the_given_week_on_anchor_day() {
        // Given
        let overview = WooPaymentsDepositsOverviewByCurrency
            .fake()
            .copy(depositInterval: .weekly(anchor: .monday))
        let currentDate = DateComponents(year: 2024, month: 1, day: 8)
        guard let date = Calendar.current.date(from: currentDate) else {
            return XCTFail("Unable to construct date.")
        }
        let nextExpectedScheduledDepositDate = "Jan 15, 2024"

        // When
        sut = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overview,
                                                           date: date)

        // Then
        assertEqual(nextExpectedScheduledDepositDate, sut.nextScheduledDeposit)
    }

    func test_when_calculateNextScheduledDeposit_is_monthly_then_next_expected_deposit_scheduled_date_is_the_given_month() {
        // Given
        let overview = WooPaymentsDepositsOverviewByCurrency
            .fake()
            .copy(depositInterval: .monthly(anchor: 12))
        let currentDate = DateComponents(year: 2024, month: 1, day: 8)
        guard let date = Calendar.current.date(from: currentDate) else {
            return XCTFail("Unable to construct date.")
        }
        let nextExpectedScheduledDepositDate = "Dec 8, 2024"

        // When
        sut = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overview,
                                                           date: date)

        // Then
        assertEqual(nextExpectedScheduledDepositDate, sut.nextScheduledDeposit)
    }

    func test_when_calculateNextScheduledDeposit_is_manual_then_next_expected_scheduled_deposit_date_is_not_applicable() {
        // Given
        let overview = WooPaymentsDepositsOverviewByCurrency
            .fake()
            .copy(depositInterval: .manual)

        // When
        sut = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overview)

        // Then
        assertEqual("N/A", sut.nextScheduledDeposit)
    }

}
