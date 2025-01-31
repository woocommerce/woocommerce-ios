import XCTest
import protocol WooFoundation.Analytics
@testable import WooCommerce

final class WooPaymentsPayoutsOverviewViewModelTests: XCTestCase {

    var sut: WooPaymentsPayoutsOverviewViewModel!
    var analyticsProvider: MockAnalyticsProvider!
    var analytics: Analytics!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = WooPaymentsPayoutsOverviewViewModel(currencyViewModels: [.init(overview: .fake().copy(currency: .GBP))],
                                                   analytics: analytics)
    }

    func test_when_tab_is_selected_analytic_event_is_tracked() {
        // Given
        let gbpViewModel = WooPaymentsPayoutsCurrencyOverviewViewModel(overview: .fake().copy(currency: .GBP))

        // When
        sut.currencySelected(currencyViewModel: gbpViewModel)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuPayoutSummaryCurrencySelected.rawValue))
        guard let index = analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.paymentsMenuPayoutSummaryCurrencySelected.rawValue),
              let properties = analyticsProvider.receivedProperties[safe: index],
              let trackedCurrencyProperty = properties[WooAnalyticsEvent.PayoutSummary.Keys.currency] as? String
        else {
            return XCTFail("Expected properties not found")
        }

        assertEqual("GBP", trackedCurrencyProperty)
    }

    func test_onAppear_when_payout_summaries_are_available_payoutSummaryShown_is_tracked() throws {
        // Given
        let currencyViewModels: [WooPaymentsPayoutsCurrencyOverviewViewModel] = [
            .init(overview: .fake().copy(currency: .GBP)),
            .init(overview: .fake().copy(currency: .EUR))
        ]
        sut = WooPaymentsPayoutsOverviewViewModel(currencyViewModels: currencyViewModels,
                                                   analytics: analytics)

        // When
        sut.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuPayoutSummaryShown.rawValue))

        guard let index = analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.paymentsMenuPayoutSummaryShown.rawValue),
              let properties = analyticsProvider.receivedProperties[safe: index],
              let trackedNumberOfCurrenciesProperty = properties[WooAnalyticsEvent.PayoutSummary.Keys.numberOfCurrencies] as? Int
        else {
            return XCTFail("Expected properties not found")
        }

        assertEqual(trackedNumberOfCurrenciesProperty, 2)
    }
}
