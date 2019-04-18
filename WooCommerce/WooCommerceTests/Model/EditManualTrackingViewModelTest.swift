import XCTest
@testable import WooCommerce
@testable import Yosemite
import UIKit

final class EditManualTrackingViewModelTest: XCTestCase {
    private var subject: EditTrackingViewModel?

    private struct MockData {
        static let order = MockOrders().sampleOrder()
        static let title = "Edit Tracking"
        static let primaryActionTitle = "Save"
        static let secondaryActiontitle = "Delete Tracking"
        static let sectionCount = 2
        static let trackingRows: [AddEditTrackingRow] = [.shippingProvider,
                                                         .trackingNumber,
                                                         .dateShipped]
        static let deleteRows: [AddEditTrackingRow] = [.deleteTracking]
        static let provider = ShipmentTrackingProvider(siteID: 1234,
                                                       name: "A mock provider",
                                                       url: "http://somewhere.internet.com")
        static let shipmentTracking = ShipmentTracking(siteID: 1234,
                                                       orderID: 5678,
                                                       trackingID: "12345678",
                                                       trackingNumber: "12345678",
                                                       trackingProvider: "A mock provider",
                                                       trackingURL: nil,
                                                       dateShipped: Date())
        static let accessoryType = UITableViewCell.AccessoryType.none
    }

    override func setUp() {
        super.setUp()
        subject = EditTrackingViewModel(order: MockData.order, shipmentTracking: MockData.shipmentTracking)
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

    func testSecondaryActionReturnsExpectation() {
        XCTAssertEqual(subject?.secondaryActionTitle, MockData.secondaryActiontitle)
    }

    func testInitialTrackingNumberMatchesTrackingInjected() {
        XCTAssertEqual(subject?.trackingNumber, MockData.shipmentTracking.trackingNumber)
    }

    func testInitialShipmentDateMatchesTrackingInjected() {
        XCTAssertEqual(subject?.shipmentDate.normalizedDate(),
                       MockData.shipmentTracking.dateShipped?.normalizedDate())
    }

    func testSectionCountIsOne() {
        XCTAssertEqual(subject?.sections.count, MockData.sectionCount)
    }

    func testRowsMatchExpectation() {
        XCTAssertEqual(subject?.sections.first?.rows, MockData.trackingRows)
        XCTAssertEqual(subject?.sections.last?.rows, MockData.deleteRows)
    }

    func testProviderCellNameContainsProviderName() {
        subject?.shipmentProvider = MockData.provider

        let cellName = subject?.providerCellName

        XCTAssertEqual(cellName, MockData.provider.name)
    }

    func testProviderCellNameAccesoryTypeMatchesExpectation() {
        XCTAssertEqual(subject?.providerCellAccessoryType, MockData.accessoryType)
    }

    func testCanCommitReturnsTrue() {
        XCTAssertTrue(subject!.canCommit)
    }

    func testIsAddingReturnsFalse() {
        XCTAssertFalse(subject!.isAdding)
    }

    func testIsCustomReturnsFalse() {
        XCTAssertFalse(subject!.isCustom)
    }
}
