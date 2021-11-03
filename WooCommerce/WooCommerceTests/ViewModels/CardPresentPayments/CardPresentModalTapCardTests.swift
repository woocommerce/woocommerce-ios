import XCTest
import TestKit
@testable import WooCommerce
@testable import Yosemite

final class CardPresentModalTapCardTests: XCTestCase {
    private var viewModel: CardPresentModalTapCard!
    private var closures: Closures!

    override func setUp() {
        super.setUp()
        closures = Closures()
        viewModel = CardPresentModalTapCard(
            name: Expectations.name,
            amount: Expectations.amount,
            onCancel: closures.onCancel()
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

    func test_topTitle_provides_expected_title() {
        XCTAssertEqual(viewModel.topTitle, Expectations.name)
    }

    func test_topSubtitle_provides_expected_title() {
        XCTAssertEqual(viewModel.topSubtitle, Expectations.amount)
    }

    func test_primary_button_title_is_nil() {
        XCTAssertNil(viewModel.primaryButtonTitle)
    }

    func test_secondary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.secondaryButtonTitle)
    }

    func test_auxiliary_button_title_is_nil() {
        XCTAssertNil(viewModel.auxiliaryButtonTitle)
    }

    func test_bottom_title_is_not_nil() {
        XCTAssertNotNil(viewModel.bottomTitle)
    }

    func test_bottom_subTitle_is_not_nil() {
        XCTAssertNotNil(viewModel.bottomSubtitle)
    }

    func test_secondary_button_calls_closure() throws {
        viewModel.didTapSecondaryButton(in: UIViewController())
        XCTAssertTrue(closures.didTapCancel)
    }
}

private extension CardPresentModalTapCardTests {
    enum Expectations {
        static var name = "name"
        static var amount = "amount"
        static var image = UIImage.cardPresentImage
    }
}

private final class Closures {
    var didTapCancel = false

    func onCancel() -> () -> Void {
        return { [weak self] in
            self?.didTapCancel = true
        }
    }
}
