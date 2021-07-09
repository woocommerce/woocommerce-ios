import XCTest
@testable import WooCommerce

final class CardPresentModalFoundReaderTests: XCTestCase {
    private var viewModel: CardPresentModalFoundReader!
    private var closures: Closures!

    override func setUp() {
        super.setUp()
        closures = Closures()
        viewModel = CardPresentModalFoundReader(name: Expectations.name, connect: closures.primaryAction(), continueSearch: closures.secondaryAction())
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

        XCTAssertTrue(closures.didTapConnect)
    }

    func test_secondary_button_action_calls_closure() {
        viewModel.didTapSecondaryButton(in: nil)

        XCTAssertTrue(closures.didTapContinue)
    }
}


private extension CardPresentModalFoundReaderTests {
    enum Expectations {
        static var name = "name"
        static var amount = "amount"
        static var image = UIImage.cardReaderFound
    }
}


private final class Closures {
    var didTapConnect = false
    var didTapContinue = false

    func primaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapConnect = true
        }
    }

    func secondaryAction() -> () -> Void {
        return {[weak self] in
            self?.didTapContinue = true
        }
    }
}
