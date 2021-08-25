import XCTest
@testable import WooCommerce

final class CardPresentModalRetryableErrorTests: XCTestCase {
    private var viewModel: CardPresentModalRetryableError!
    private var closures: Closures!

    override func setUp() {
        super.setUp()
        closures = Closures()
        viewModel = CardPresentModalRetryableError(primaryAction: closures.primaryAction())
    }

    override func tearDown() {
        viewModel = nil
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

    func test_auxiliary_button_title_is_nil() {
        XCTAssertNil(viewModel.auxiliaryButtonTitle)
    }

    func test_bottom_title_is_nil() {
        XCTAssertNil(viewModel.bottomTitle)
    }

    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }

    func test_primary_button_action_calls_closure() {
        viewModel.didTapPrimaryButton(in: UIViewController())

        XCTAssertTrue(closures.didTapRetry)
    }
}


private extension CardPresentModalRetryableErrorTests {
    enum Expectations {
        static var image = UIImage.paymentErrorImage
    }
}

private final class Closures {
    var didTapRetry = false

    func primaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapRetry = true
        }
    }
}
