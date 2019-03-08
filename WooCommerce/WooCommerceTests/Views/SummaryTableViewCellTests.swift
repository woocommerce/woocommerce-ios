import XCTest
@testable import WooCommerce
@testable import Yosemite

final class SummaryTableViewCellTests: XCTestCase {
    private var cell: SummaryTableViewCell?

    override func setUp() {
        super.setUp()
        let nib = Bundle.main.loadNibNamed("SummaryTableViewCell", owner: self, options: nil)
        cell = nib?.first as? SummaryTableViewCell
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testTitleSetsTitleLabelText() {
        let mockTitle = "Automattic"
        cell?.title = mockTitle

        XCTAssertEqual(cell?.getTitle().text, mockTitle)
    }

    func testDateCreatedSetsDateLabelText() {
        let mockDate = Date().toString(dateStyle: .medium, timeStyle: .short)
        cell?.dateCreated = mockDate

        XCTAssertEqual(cell?.getCreatedLabel().text, mockDate)
    }

    func testDisplayStatusSetsPaymentDateLabel() {
        let mockStatus = OrderStatus(name: "Automattic", siteID: 0, slug: "automattic", total: 0)
        cell?.display(orderStatus: mockStatus)

        XCTAssertEqual(cell?.getStatusLabel().text, mockStatus.name)
    }

    func testTappingButtonExecutesCallback() {
        let expect = expectation(description: "The action assigned gets called")
        cell?.onEditTouchUp = {
            expect.fulfill()
        }

        cell?.getEditButton().sendActions(for: .touchUpInside)

        waitForExpectations(timeout: 1, handler: nil)
    }

    func testTitleLabelIsAppliedHeadStyle() {
        let mockLabel = UILabel()
        mockLabel.applyHeadlineStyle()

        let cellTitleLabel = cell?.getTitle()

        XCTAssertEqual(cellTitleLabel?.font, mockLabel.font)
        XCTAssertEqual(cellTitleLabel?.textColor, mockLabel.textColor)
    }

    func testCreatedLabelIsAppliedHeadStyle() {
        let mockLabel = UILabel()
        mockLabel.applyFootnoteStyle()

        let cellCreatedLabel = cell?.getCreatedLabel()

        XCTAssertEqual(cellCreatedLabel?.font, mockLabel.font)
        XCTAssertEqual(cellCreatedLabel?.textColor, mockLabel.textColor)
    }

    func testStatusLabelIsAppliedPaddedLabelStyle() {
        let mockLabel = UILabel()
        mockLabel.applyPaddedLabelDefaultStyles()

        let cellStatusLabel = cell?.getStatusLabel()

        XCTAssertEqual(cellStatusLabel?.font, mockLabel.font)
        XCTAssertEqual(cellStatusLabel?.layer.borderWidth, mockLabel.layer.borderWidth)
        XCTAssertEqual(cellStatusLabel?.layer.cornerRadius, mockLabel.layer.cornerRadius)
    }
}
