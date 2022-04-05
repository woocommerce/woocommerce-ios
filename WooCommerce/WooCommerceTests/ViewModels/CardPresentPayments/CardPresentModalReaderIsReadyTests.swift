import XCTest
import TestKit
@testable import WooCommerce
@testable import Yosemite

final class CardPresentModalReaderIsReadyTests: XCTestCase {
    private var viewModel: CardPresentModalReaderIsReady!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        viewModel = CardPresentModalReaderIsReady(name: Expectations.name,
                                                  amount: Expectations.amount,
                                                  paymentGatewayAccountID: Expectations.paymentGatewayAccountID,
                                                  countryCode: Expectations.countryCode,
                                                  cardReaderModel: Expectations.cardReaderModel,
                                                  analytics: analytics)
    }

    override func tearDown() {
        viewModel = nil
        analytics = nil
        analyticsProvider = nil
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

    func test_secondary_button_dispatched_cancel_action() throws {
        let storesManager = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        storesManager.reset()

        ServiceLocator.setStores(storesManager)

        assertEmpty(storesManager.receivedActions)

        viewModel.didTapSecondaryButton(in: nil)

        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? CardPresentPaymentAction)
        switch action {
        case .cancelPayment(onCompletion: _):
            XCTAssertTrue(true)
        default:
            XCTFail("Primary button failed to dispatch .cancelPayment action")
        }
    }

    func test_tapping_secondary_button_tracks_cancel_event() throws {
        // Given
        assertEmpty(analyticsProvider.receivedEvents)

        // When
        viewModel.didTapSecondaryButton(in: nil)

        // Then
        XCTAssertEqual(analyticsProvider.receivedEvents.count, 1)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, "card_present_collect_payment_canceled")

        let firstPropertiesBatch = try XCTUnwrap(analyticsProvider.receivedProperties.first)
        XCTAssertEqual(firstPropertiesBatch["card_reader_model"] as? String, Expectations.cardReaderModel)
        XCTAssertEqual(firstPropertiesBatch["country"] as? String, Expectations.countryCode)
        XCTAssertEqual(firstPropertiesBatch["plugin_slug"] as? String, Expectations.paymentGatewayAccountID)
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
