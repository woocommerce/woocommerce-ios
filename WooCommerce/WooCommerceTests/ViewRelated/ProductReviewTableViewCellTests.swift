import XCTest
@testable import WooCommerce

final class ProductReviewTableViewCellTests: XCTestCase {
    private var cell: ProductReviewTableViewCell!
    private var viewModel: ReviewViewModel!

    override func setUp() {
        super.setUp()
        viewModel = mockViewModel()
        let nib = Bundle.main.loadNibNamed("ProductReviewTableViewCell", owner: self, options: nil)
        cell = nib?.first as? ProductReviewTableViewCell

        cell?.configure(with: mockViewModel())
    }

    override func tearDown() {
        cell = nil
        super.tearDown()
    }

    func testCellIconMatchesViewModel() {
        XCTAssertEqual(cell.getNotIconLabel().text, viewModel.notIcon)
    }

    func testCellSubjectMatchesViewModel() {
        XCTAssertEqual(cell.getSubjectLabel().text, viewModel.subject)
    }

    func testCellRatingMatchesViewModel() {
        XCTAssertEqual(cell.getStarRatingView().rating, CGFloat(viewModel.rating))
    }

    func testCellRatingStarSizeIs13() {
        XCTAssertEqual(cell.getStarRatingView().starImage.size, CGSize(width: 13, height: 13))
    }

    func testCellRatingSEmptytarSizeIs13() {
        XCTAssertEqual(cell.getStarRatingView().emptyStarImage.size, CGSize(width: 13, height: 13))
    }
}


private extension ProductReviewTableViewCellTests {
    func mockViewModel() -> ReviewViewModel {
        let mocks = MockReviews()
        return ReviewViewModel(review: mocks.review(),
                               product: mocks.product(),
                               notification: mocks.emptyNotification())
    }
}
