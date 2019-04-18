import XCTest
@testable import WooCommerce

final class AddManualCustomTrackingViewModelTests: XCTestCase {
    private var subject: AddTrackingViewModel?

    private struct MockData {
        static let order = MockOrders().sampleOrder()
        static let title = "Add Tracking"
        static let primaryActionTitle = "Add"
        static let sectionCount = 1
        static let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                         .providerName,
                                                         .trackingNumber,
                                                         .trackingLink,
                                                         .dateShipped,
                                                         .datePicker]

        static let accessoryType = UITableViewCell.AccessoryType.none
    }

    override func setUp() {
        super.setUp()
        subject = AddTrackingViewModel(order: MockData.order)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func testSiteIDRemainsUnchanged() {
        XCTAssertEqual(subject?.order.siteID, MockData.order.siteID)
    }

    func testOrderIDRemainsUnchanged() {
        XCTAssertEqual(subject?.order.orderID, MockData.order.orderID)
    }

    func testTitleReturnsExpectation() {
        XCTAssertEqual(subject?.title, MockData.title)
    }

    func testPrimaryActionTitleReturnsExpectation() {
        XCTAssertEqual(subject?.primaryActionTitle, MockData.primaryActionTitle)
    }

    func testSecondaryActionTitleIsNil() {
        XCTAssertNil(subject?.secondaryActionTitle)
    }
    func testInitialTrackingNumberIsNil() {
        XCTAssertNil(subject?.trackingNumber)
    }

    func testInitialShipmentDateIsToday() {
        let date = subject?.shipmentDate

        XCTAssertEqual(date?.normalizedDate(), Date().normalizedDate())
    }
}
