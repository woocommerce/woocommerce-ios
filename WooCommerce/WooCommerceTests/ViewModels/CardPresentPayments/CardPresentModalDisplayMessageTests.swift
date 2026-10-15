import XCTest
@testable import WooCommerce

final class CardPresentModalDisplayMessageTests: XCTestCase {
    private var viewModel: CardPresentModalDisplayMessage!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        viewModel = CardPresentModalDisplayMessage(name: Expectations.name, amount: Expectations.amount, message: Expectations.message)
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    @MainActor
    func test_viewmodel_provides_expected_image() {
        XCTAssertEqual(viewModel.image, Expectations.image)
    }

    @MainActor
    func test_topTitle_provides_expected_title() {
        XCTAssertEqual(viewModel.topTitle, Expectations.name)
    }

    @MainActor
    func test_topSubtitle_provides_expected_title() {
        XCTAssertEqual(viewModel.topSubtitle, Expectations.amount)
    }

    @MainActor
    func test_primary_button_title_is_nil() {
        XCTAssertNil(viewModel.primaryButtonTitle)
    }

    @MainActor
    func test_secondary_button_title_is_nil() {
        XCTAssertNil(viewModel.secondaryButtonTitle)
    }

    @MainActor
    func test_auxiliary_button_title_is_nil() {
        XCTAssertNil(viewModel.auxiliaryButtonTitle)
    }

    @MainActor
    func test_bottom_title_provides_expected_message() {
        XCTAssertEqual(viewModel.bottomTitle, Expectations.message)
    }

    @MainActor
    func test_bottom_subTitle_is_nil() {
        XCTAssertNil(viewModel.bottomSubtitle)
    }
}


private extension CardPresentModalDisplayMessageTests {
    enum Expectations {
        static let name = "name"
        static let amount = "amount"
        static let image = UIImage.cardPresentImage
        static let message = "message"
    }
}
