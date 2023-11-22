import XCTest
@testable import WooCommerce

final class WooPaymentsDepositsOverviewViewModelTests: XCTestCase {

    var sut: WooPaymentsDepositsOverviewViewModel!
    var analyticsProvider: MockAnalyticsProvider!

    override func setUp() {
        analyticsProvider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: analyticsProvider)
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
}
