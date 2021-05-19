import XCTest
import TestKit
@testable import WooCommerce
@testable import Yosemite

final class CardPresentModalReaderIsReadyTests: XCTestCase {
    private var viewModel: CardPresentModalReaderIsReady!

    override func setUp() {
        super.setUp()
        viewModel = CardPresentModalReaderIsReady(name: Expectations.name, amount: Expectations.amount)
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

    func test_primary_button_title_is_not_nil() {
        XCTAssertNotNil(viewModel.primaryButtonTitle)
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

    func test_bottom_subTitle_is_not_nil() {
        XCTAssertNotNil(viewModel.bottomSubtitle)
    }

    func test_primary_button_dispatched_cancel_action() throws {
        let storesManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        storesManager.reset()

        ServiceLocator.setStores(storesManager)

        assertEmpty(storesManager.receivedActions)

        viewModel.didTapPrimaryButton(in: nil)

        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? CardPresentPaymentAction)
        switch action {
        case .cancelPayment(onCompletion: _):
            XCTAssertTrue(true)
        default:
            XCTFail("Primary button does not dispatch .cancelPayment action")
        }
    }
}


private extension CardPresentModalReaderIsReadyTests {
    enum Expectations {
        static var name = "name"
        static var amount = "amount"
        static var image = UIImage.cardPresentImage
    }
}
