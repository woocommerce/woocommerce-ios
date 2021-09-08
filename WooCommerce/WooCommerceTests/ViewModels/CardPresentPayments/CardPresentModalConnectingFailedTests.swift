import XCTest
@testable import WooCommerce

final class CardPresentModalConnectingFailedTests: XCTestCase {
    private var viewModel: CardPresentModalConnectingFailed!
    private var closures: Closures!

    override func setUp() {
        super.setUp()
        closures = Closures()
        viewModel = CardPresentModalConnectingFailed(
            continueSearch: closures.continueSearch(),
            cancelSearch: closures.cancelSearch()
        )
    }

    override func tearDown() {
        viewModel = nil
        closures = nil
        super.tearDown()
    }

    func test_viewmodel_provides_expected_image() {
        XCTAssertEqual(viewModel.image, Expectations.image)
    }

    func test_topTitle_is_not_nil() {
        XCTAssertNotNil(viewModel.topTitle)
    }

    func test_topSubtitle_is_nil() {
        XCTAssertNil(viewModel.topSubtitle)
    }

    func test_primary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.primaryButtonTitle)
    }

    func test_secondary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.secondaryButtonTitle)
    }

    func test_bottom_title_is_nil() {
        XCTAssertNil(viewModel.bottomTitle)
    }

    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }
}

private extension CardPresentModalConnectingFailedTests {
    enum Expectations {
        static let image = UIImage.paymentErrorImage
    }
}

private final class Closures {
    var didTapContinueSearch = false
    var didTapCancelSearch = false

    func continueSearch() -> () -> Void {
        return {[weak self] in
            self?.didTapContinueSearch = true
        }
    }

    func cancelSearch() -> () -> Void {
        return {[weak self] in
            self?.didTapCancelSearch = true
        }
    }
}
