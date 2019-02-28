import XCTest
@testable import WooCommerce
@testable import Yosemite

final class OrderTrackingTableViewCellTests: XCTestCase {
    private var cell: OrderTrackingTableViewCell?

    private struct MockData {
        static let tracking = ShipmentTracking(siteID: 0,
                                               orderID: 0,
                                               trackingID: "mock-tracking-id",
                                               trackingNumber: "XXX_YYY_ZZZ",
                                               trackingProvider: "HK POST",
                                               trackingURL: "http://automattic.com",
                                               dateShipped: nil)

        static let buttonTitle = "Track shipment"
    }

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("OrderTrackingTableViewCell", owner: self, options: nil)
        cell = nib?.first as? OrderTrackingTableViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testTopLineTextMatchesTrackingProvider() {
        populateCell()

        XCTAssertEqual(cell?.getTopLabel().text, MockData.tracking.trackingProvider)
    }

    func testBottomLineTextMatchesTrackingNumber() {
        populateCell()

        XCTAssertEqual(cell?.getBottomLabel().text, MockData.tracking.trackingNumber)
    }

    func testActionButtonExecutesCallback() {
        let expect = expectation(description: "The action assigned to the cell gets called when the cell button is tapped")

        cell?.onActionTouchUp = {
            expect.fulfill()
        }

        cell?.getActionButton().sendActions(for: .touchUpInside)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTopLabelHasHeadlineStyle() {
        let mockLabel = UILabel()
        mockLabel.applyHeadlineStyle()

        let cellLabel = cell?.getTopLabel()

        XCTAssertEqual(cellLabel?.font, mockLabel.font)
        XCTAssertEqual(cellLabel?.textColor, mockLabel.textColor)
    }

    func testBottomLabelHasSubheadlineStyle() {
        let mockLabel = UILabel()
        mockLabel.applySubheadlineStyle()

        let cellLabel = cell?.getBottomLabel()

        XCTAssertEqual(cellLabel?.font, mockLabel.font)
        XCTAssertEqual(cellLabel?.textColor, mockLabel.textColor)
    }

    func testTopLabelAccessibilityLabelMatchesExpectation() {
        populateCell()

        let expectedLabel = String.localizedStringWithFormat(
            NSLocalizedString("Shipment Company %@",
                                                                               comment: "Accessibility label for Shipment tracking company in Order details screen. "
                                                                                + "Reads like: Shipment Company USPS"),
                                                             MockData.tracking.trackingProvider ?? "")

        XCTAssertEqual(cell?.getTopLabel().accessibilityLabel, expectedLabel)
    }

    func testBottomLabelAccessibilityLabelMatchesExpectation() {
        populateCell()

        let expectedLabel = String.localizedStringWithFormat(
            NSLocalizedString("Tracking number %@",
                                                                               comment: "Accessibility label for Shipment tracking number in Order details screen."
                                                                                + " Reads like: Tracking Number 1AZ234567890"),
                                                             MockData.tracking.trackingNumber)

        XCTAssertEqual(cell?.getBottomLabel().accessibilityLabel, expectedLabel)
    }

    func testButtonAccessibilityLabelMatchesExpectation() {
        populateCell()

        XCTAssertEqual(cell?.getActionButton().accessibilityLabel, MockData.buttonTitle)
    }

    func testButtonAccessibilityhintMatchesExpectation() {
        populateCell()

        let expectedHint = NSLocalizedString("Tracks a shipment.",
                                             comment: "Accessibility hint for"
                                                + " Track Package button in Order details screen")

        XCTAssertEqual(cell?.getActionButton().accessibilityHint, expectedHint)
    }

    private func populateCell() {
        cell?.topText = MockData.tracking.trackingProvider
        cell?.bottomText = MockData.tracking.trackingNumber
        cell?.actionButtonNormalText = MockData.buttonTitle
    }
}
