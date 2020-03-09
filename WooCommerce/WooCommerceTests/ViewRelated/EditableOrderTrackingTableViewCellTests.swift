import XCTest
@testable import WooCommerce
@testable import Yosemite

final class EditableOrderTrackingTableViewCellTests: XCTestCase {
    private var cell: EditableOrderTrackingTableViewCell?

    private struct MockData {
        static let localizedShipmentDate = Date(timeIntervalSince1970: 0).toString(dateStyle: .medium, timeStyle: .none)
        static let tracking = ShipmentTracking(siteID: 0,
                                               orderID: 0,
                                               trackingID: "mock-tracking-id",
                                               trackingNumber: "XXX_YYY_ZZZ",
                                               trackingProvider: "HK POST",
                                               trackingURL: "http://automattic.com",
                                               dateShipped: Date(timeIntervalSince1970: 0))

        static let buttonTitle = "Track shipment"
    }

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("EditableOrderTrackingTableViewCell", owner: self, options: nil)
        cell = nib?.first as? EditableOrderTrackingTableViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testTopLineTextMatchesTrackingProvider() {
        populateCell()

        XCTAssertEqual(cell?.getTopLabel().text, MockData.tracking.trackingProvider)
    }

    func testMiddleLineTextMatchesTrackingNumber() {
        populateCell()

        XCTAssertEqual(cell?.getMiddleLabel().text, MockData.tracking.trackingNumber)
    }

    func testBottomLineTextMatchesShipmentDate() {
        populateCell()

        XCTAssertEqual(cell?.getBottomLabel().text, MockData.localizedShipmentDate)
    }

    func testTopLabelHasBodyStyle() {
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        let cellLabel = cell?.getTopLabel()

        XCTAssertEqual(cellLabel?.font, mockLabel.font)
        XCTAssertEqual(cellLabel?.textColor, mockLabel.textColor)
    }

    func testMiddleLabelHasHeadlineStyle() {
        let mockLabel = UILabel()
        mockLabel.applyHeadlineStyle()

        let cellLabel = cell?.getMiddleLabel()

        XCTAssertEqual(cellLabel?.font, mockLabel.font)
        XCTAssertEqual(cellLabel?.textColor, mockLabel.textColor)
    }

    func testBottomLabelHasBodyStyle() {
        let mockLabel = UILabel()
        mockLabel.applyBodyStyle()

        let cellLabel = cell?.getBottomLabel()

        XCTAssertEqual(cellLabel?.font, mockLabel.font)
        XCTAssertEqual(cellLabel?.textColor, mockLabel.textColor)
    }

    func testTopLabelAccessibilityLabelMatchesExpectation() {
        populateCell()

        let shipmentCompany = NSLocalizedString("Shipment Company %@", comment: "A unit test string for order tracking. Reads as: 'Shipment Company HK Post'")
        let expectedLabel = String.localizedStringWithFormat(shipmentCompany,
                                                             MockData.tracking.trackingProvider ?? "")

        XCTAssertEqual(cell?.getTopLabel().accessibilityLabel, expectedLabel)
    }

    func testMiddleLabelAccessibilityLabelMatchesExpectation() {
        populateCell()

        let trackingNumber = NSLocalizedString("Tracking number %@",
                                               comment: "A unit test string. Reads as: 'Trackin number XXX_YYY_ZZZ'")
        let expectedLabel = String.localizedStringWithFormat(trackingNumber,
                                                             MockData.tracking.trackingNumber)

        XCTAssertEqual(cell?.getMiddleLabel().accessibilityLabel, expectedLabel)
    }
}


private extension EditableOrderTrackingTableViewCellTests {
    private func populateCell() {
        cell?.topText = MockData.tracking.trackingProvider
        cell?.middleText = MockData.tracking.trackingNumber
        cell?.bottomText = MockData.localizedShipmentDate
    }
}
