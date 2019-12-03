import XCTest
@testable import WooCommerce

final class AddManualCustomTrackingViewModelTests: XCTestCase {
    private var subject: AddCustomTrackingViewModel?

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
        static let initialName = "Hogsmeade"
    }

    override func setUp() {
        super.setUp()
        subject = AddCustomTrackingViewModel(order: MockData.order)
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

    func testSectionCountIsOne() {
        XCTAssertEqual(subject?.sections.count, MockData.sectionCount)
    }

    func testRowsMatchExpectation() {
        XCTAssertEqual(subject?.sections.first?.rows, MockData.trackingRows)
    }

    func testRowsDoesNotContainDelete() {
        let rows = subject?.sections.first?.rows
        let rowsContainsDelete = rows?.contains(.deleteTracking)

        XCTAssertFalse(rowsContainsDelete!)
    }

    func testIsAddingReturnsTrue() {
        XCTAssertTrue(subject!.isAdding)
    }

    func testIsCustomReturnsTrue() {
        XCTAssertTrue(subject!.isCustom)
    }

    func testCanCommitReturnsTrueWithNameAndTrackingNumberAndURL() {
        subject?.providerName = "A name"
        subject?.trackingNumber = "123"
        subject?.trackingLink = "somewhere.com"

        XCTAssertTrue(subject!.canCommit)
    }

    func testCanCommitReturnsTrueWithNameAndTrackingNumberAndNoURL() {
        subject?.providerName = "A name"
        subject?.trackingNumber = "123"

        XCTAssertTrue(subject!.canCommit)
    }

    func testCanCommitReturnsFalseWithoutName() {
        subject?.trackingNumber = "123"

        XCTAssertFalse(subject!.canCommit)
    }

    func testCanCommitReturnsFalseWithoutTrackingNumber() {
        subject?.providerName = "A name"

        XCTAssertFalse(subject!.canCommit)
    }

    func testCanCommitReturnsFalseWithoutNameAndWithoutTrackingNumber() {
        XCTAssertFalse(subject!.canCommit)
    }

    func testInitialisingWithProviderNameReturnsName() {
        let viewModel = AddCustomTrackingViewModel(order: MockData.order, initialName: MockData.initialName)

        XCTAssertEqual(viewModel.providerName, MockData.initialName)
    }
}
