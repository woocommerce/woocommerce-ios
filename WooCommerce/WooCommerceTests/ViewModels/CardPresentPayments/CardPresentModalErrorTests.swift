import XCTest
@testable import WooCommerce

final class CardPresentModalErrorTests: XCTestCase {
    private var viewModel: CardPresentModalError!
    private var closures: Closures!

    override func setUp() {
        super.setUp()
        closures = Closures()
        viewModel = CardPresentModalError(amount: Expectations.amount, error: Expectations.error, primaryAction: closures.primaryAction())
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

    func test_topSubtitle_provides_expected_title() {
        XCTAssertEqual(viewModel.topSubtitle, Expectations.amount)
    }

    func test_primary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.primaryButtonTitle)
    }

    func test_secondary_button_title_is_nil() {
        XCTAssertNil(viewModel.secondaryButtonTitle)
    }

    func test_bottom_title_is_not_nil() {
        XCTAssertNotNil(viewModel.bottomTitle)
    }

    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }

    func test_primary_button_action_calls_closure() {
        viewModel.didTapPrimaryButton(in: nil)

        XCTAssertTrue(closures.didTapPrimary)
    }
}


private extension CardPresentModalErrorTests {
    enum Expectations {
        static let amount = "amount"
        static let image = UIImage.paymentErrorImage
        static let error = MockError()
    }

    final class MockError: Error {
        var localizedDescription: String {
            "description"
        }
    }
}


private final class Closures {
    var didTapPrimary = false

    func primaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapPrimary = true
        }
    }
}
