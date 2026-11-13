import XCTest
@testable import WooCommerce

final class ProductReviewTableViewCellTests: XCTestCase {

    @MainActor
    func testCellIconMatchesViewModel() throws {
        let (cell, viewModel) = try makeSUT()
        XCTAssertEqual(cell.getNotIconLabel().text, viewModel.notIcon)
    }

    @MainActor
    func testCellSubjectMatchesViewModel() throws {
        let (cell, viewModel) = try makeSUT()
        XCTAssertEqual(cell.getSubjectLabel().text, viewModel.subject)
    }

    @MainActor
    func testCellRatingMatchesViewModel() throws {
        let (cell, viewModel) = try makeSUT()
        XCTAssertEqual(cell.getStarRatingView().rating, CGFloat(viewModel.rating))
    }

    @MainActor
    func testCellRatingStarSizeIs13() throws {
        let (cell, _) = try makeSUT()
        XCTAssertEqual(cell.getStarRatingView().starImage.size, CGSize(width: 13, height: 13))
    }

    @MainActor
    func testCellRatingSEmptytarSizeIs13() throws {
        let (cell, _) = try makeSUT()
        XCTAssertEqual(cell.getStarRatingView().emptyStarImage.size, CGSize(width: 13, height: 13))
    }
}


private extension ProductReviewTableViewCellTests {
    @MainActor
    func makeSUT() throws -> (cell: ProductReviewTableViewCell, viewModel: ReviewViewModel) {
        let viewModel = mockViewModel()
        let nib = Bundle.main.loadNibNamed("ProductReviewTableViewCell", owner: self, options: nil)
        let cell = try XCTUnwrap(nib?.first as? ProductReviewTableViewCell)
        cell.configure(with: viewModel)
        return (cell, viewModel)
    }

    func mockViewModel() -> ReviewViewModel {
        let mocks = MockReviews()
        return ReviewViewModel(review: mocks.review(),
                               product: mocks.product(),
                               notification: mocks.emptyNotification())
    }
}
