import XCTest
@testable import WooCommerce

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
}
