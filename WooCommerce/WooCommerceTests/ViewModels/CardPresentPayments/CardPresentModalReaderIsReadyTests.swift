import XCTest
import TestKit
@testable import WooCommerce
@testable import Yosemite

final class CardPresentModalReaderIsReadyTests: XCTestCase {
    private var viewModel: CardPresentModalReaderIsReady!

    override func setUp() {
        super.setUp()
        viewModel = CardPresentModalReaderIsReady(name: Expectations.name,
                                                  amount: Expectations.amount,
                                                  cancelAction: {})
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

}


private extension CardPresentModalReaderIsReadyTests {
    enum Expectations {
        static let name = "name"
        static let amount = "amount"
        static let image = UIImage.cardPresentImage
        static let cardReaderModel = "WISEPAD_3"
        static let countryCode = "CA"
        static let paymentGatewayAccountID = "woocommerce-payments"
    }
}
