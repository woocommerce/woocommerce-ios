import XCTest
@testable import WooCommerce

final class CardPresentModalDisplayMessageTests: XCTestCase {
    private var viewModel: CardPresentModalDisplayMessage!

    override func setUp() {
        super.setUp()
        viewModel = CardPresentModalDisplayMessage(name: Expectations.name, amount: Expectations.amount, message: Expectations.message)
    }

    override func tearDown() {
        viewModel = nil
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

    func test_secondary_button_title_is_nil() {
        XCTAssertNil(viewModel.secondaryButtonTitle)
    }

    func test_auxiliary_button_title_is_nil() {
        XCTAssertNil(viewModel.auxiliaryButtonTitle)
    }

    func test_bottom_title_provides_expected_message() {
        XCTAssertEqual(viewModel.bottomTitle, Expectations.message)
    }

    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }
}


private extension CardPresentModalDisplayMessageTests {
    enum Expectations {
        static var name = "name"
        static var amount = "amount"
        static var image = UIImage.cardPresentImage
        static var message = "message"
    }
}
