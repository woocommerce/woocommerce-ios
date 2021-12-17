import XCTest
@testable import WooCommerce

final class CardPresentModalSuccessWithoutEmailTests: XCTestCase {
    private var viewModel: CardPresentModalSuccessWithoutEmail!
    private var closures: Closures!

    override func setUp() {
        super.setUp()
        closures = Closures()
        viewModel = CardPresentModalSuccessWithoutEmail(printReceipt: closures.printReceipt(),
                                                        noReceiptTitle: "Back",
                                                        noReceiptAction: closures.noReceiptAction())
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
        XCTAssertEqual(viewModel.secondaryButtonTitle, "Back")
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

        XCTAssertTrue(closures.didTapPrint)
    }

    func test_secondary_button_action_calls_closure() {
        viewModel.didTapSecondaryButton(in: UIViewController())

        XCTAssertTrue(closures.didTapNoReceipt)
    }
}


private extension CardPresentModalSuccessWithoutEmailTests {
    enum Expectations {
        static var image = UIImage.celebrationImage
    }
}


private final class Closures {
    var didTapPrint = false
    var didTapNoReceipt = false

    func printReceipt() -> () -> Void {
        return { [weak self] in
            self?.didTapPrint = true
        }
    }

    func noReceiptAction() -> () -> Void {
        return { [weak self] in
            self?.didTapNoReceipt = true
        }
    }
}
