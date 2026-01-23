import XCTest
@testable import WooCommerce
@testable import Yosemite
import UIKit

final class AddManualTrackingViewModelTests: XCTestCase {
    private var subject: AddTrackingViewModel?

    private struct MockData {
        static let order = MockOrders().sampleOrder()
        static let title = NSLocalizedString("Add Tracking", comment: "This text appears as the navigation bar title on the screen where users manually add shipment tracking information to orders, and also as a button label in the order details screen that opens this tracking creation flow.")
        static let primaryActionTitle = NSLocalizedString("Add", comment: "Button label that appears in shipment tracking screens and order note screens. When tapped, it adds a new tracking entry or saves a new order note respectively.")
        static let sectionCount = 1
        static let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                         .trackingNumber,
                                                         .dateShipped,
                                                         .datePicker]
        static let provider = ShipmentTrackingProvider(siteID: 1234,
                                                       name: "A mock provider",
                                                       url: "http://somewhere.internet.com")
        static let accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
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

    func testProviderCellNameContainsProviderName() {
        subject?.shipmentProvider = MockData.provider

        let cellName = subject?.providerCellName

        XCTAssertEqual(cellName, MockData.provider.name)
    }

    func testProviderCellNameAccesoryTypeMatchesExpectation() {
        XCTAssertEqual(subject?.providerCellAccessoryType, MockData.accessoryType)
    }

    func testCanCommitReturnsFalseIfProviderIsNotSet() {
        XCTAssertFalse(subject!.canCommit)
    }

    func testCanCommitReturnsFalseIfProviderIsSetButTrackingNumberIsNotSet() {
        subject?.shipmentProvider = MockData.provider

        XCTAssertFalse(subject!.canCommit)
    }

    func testCanCommitReturnsFalseIfProviderIsNotSetAndTrackingNumberIsSet() {
        subject?.trackingNumber = "1234"

        XCTAssertFalse(subject!.canCommit)
    }

    func testCanCommitReturnsTrueIfProviderAndTrackingNumberAreNotSet() {
        subject?.shipmentProvider = MockData.provider
        subject?.trackingNumber = "1234"

        XCTAssertTrue(subject!.canCommit)
    }

    func testIsAddingReturnsTrue() {
        XCTAssertTrue(subject!.isAdding)
    }

    func testIsCustomReturnsFalse() {
        XCTAssertFalse(subject!.isCustom)
    }
}
