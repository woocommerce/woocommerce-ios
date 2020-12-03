import XCTest
@testable import Yosemite
@testable import WooCommerce

final class OrderDetailsViewModelTests: XCTestCase {
    private var order: Order!
    private var viewModel: OrderDetailsViewModel!

    override func setUp() {
        order = MockOrders().sampleOrder()
        viewModel = OrderDetailsViewModel(order: order)
        let analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider())
        ServiceLocator.setAnalytics(analytics)
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        viewModel = nil
        order = nil
    }

    func testDeleteTrackingFiresOrderTrackingDeleteTracksEvent() {
        let mockShipmentTracking = ShipmentTracking(siteID: 1111,
                                                    orderID: 1111,
                                                    trackingID: "1111",
                                                    trackingNumber: "1111",
                                                    trackingProvider: nil,
                                                    trackingURL: nil,
                                                    dateShipped: nil)

        viewModel.deleteTracking(mockShipmentTracking) { _ in }

        let analytics = ServiceLocator.analytics.analyticsProvider as! MockAnalyticsProvider
        let receivedEvents = analytics.receivedEvents

        XCTAssert(receivedEvents.contains(WooAnalyticsStat.orderTrackingDelete.rawValue))
    }

    func testFormattedDateCreatedDoesNotIncludeTheYearForDatesWithTheSameYear() {
        let order = MockOrders().sampleOrderCreatedInCurrentYear()
        let viewModel = OrderDetailsViewModel(order: order)
        let expectedYearString = DateFormatter.yearFormatter.string(from: order.dateCreated)

        let formatted = viewModel.formattedDateCreated

        XCTAssertFalse(formatted.contains(expectedYearString))
    }

    func testFormattedDateCreatedIncludesTheYearForDatesThatAreNotInTheSameYear() {
        let order = MockOrders().sampleOrder()
        let viewModel = OrderDetailsViewModel(order: order)
        let expectedYearString = DateFormatter.yearFormatter.string(from: order.dateCreated)

        let formatted = viewModel.formattedDateCreated

        XCTAssertTrue(formatted.contains(expectedYearString))
    }
}
