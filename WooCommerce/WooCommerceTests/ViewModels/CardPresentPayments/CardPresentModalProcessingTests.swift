import XCTest
@testable import WooCommerce

final class CardPresentModalProcessingTests: XCTestCase {
    private var viewModel: CardPresentModalProcessing!

    override func setUp() {
        super.setUp()
        viewModel = CardPresentModalProcessing(name: Expectations.name, amount: Expectations.amount)
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

    func test_bottom_title_is_not_nil() {
        XCTAssertNotNil(viewModel.bottomTitle)
    }

    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }
}


private extension CardPresentModalProcessingTests {
    enum Expectations {
        static var name = "name"
        static var amount = "amount"
        static var image = UIImage.cardPresentImage
    }
}
