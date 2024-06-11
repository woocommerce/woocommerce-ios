import XCTest
import protocol WooFoundation.Analytics
@testable import WooCommerce

final class WooPaymentsDepositsOverviewViewModelTests: XCTestCase {

    var sut: WooPaymentsDepositsOverviewViewModel!
    var analyticsProvider: MockAnalyticsProvider!
    var analytics: Analytics!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        sut = WooPaymentsDepositsOverviewViewModel(currencyViewModels: [.init(overview: .fake().copy(currency: .GBP))],
                                                   analytics: analytics)
    }

    func test_when_tab_is_selected_analytic_event_is_tracked() {
        // Given
        let gbpViewModel = WooPaymentsDepositsCurrencyOverviewViewModel(overview: .fake().copy(currency: .GBP))

        // When
        sut.currencySelected(currencyViewModel: gbpViewModel)

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuDepositSummaryCurrencySelected.rawValue))
        guard let index = analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.paymentsMenuDepositSummaryCurrencySelected.rawValue),
              let properties = analyticsProvider.receivedProperties[safe: index],
              let trackedCurrencyProperty = properties[WooAnalyticsEvent.DepositSummary.Keys.currency] as? String
        else {
            return XCTFail("Expected properties not found")
        }

        assertEqual("GBP", trackedCurrencyProperty)
    }

    func test_onAppear_when_deposit_summaries_are_available_depositSummaryShown_is_tracked() throws {
        // Given
        let currencyViewModels: [WooPaymentsDepositsCurrencyOverviewViewModel] = [
            .init(overview: .fake().copy(currency: .GBP)),
            .init(overview: .fake().copy(currency: .EUR))
        ]
        sut = WooPaymentsDepositsOverviewViewModel(currencyViewModels: currencyViewModels,
                                                   analytics: analytics)

        // When
        sut.onAppear()

        // Then
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.paymentsMenuDepositSummaryShown.rawValue))

        guard let index = analyticsProvider.receivedEvents.firstIndex(of: WooAnalyticsStat.paymentsMenuDepositSummaryShown.rawValue),
              let properties = analyticsProvider.receivedProperties[safe: index],
              let trackedNumberOfCurrenciesProperty = properties[WooAnalyticsEvent.DepositSummary.Keys.numberOfCurrencies] as? Int
        else {
            return XCTFail("Expected properties not found")
        }

        assertEqual(trackedNumberOfCurrenciesProperty, 2)
    }
}
