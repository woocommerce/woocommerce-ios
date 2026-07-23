import XCTest
@testable import WooCommerce
import Hardware
import WooFoundation

final class CardPresentPaymentReceiptEmailCoordinatorTests: XCTestCase {
    private var coordinator: CardPresentPaymentReceiptEmailCoordinator!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        coordinator = CardPresentPaymentReceiptEmailCoordinator(analytics: analytics,
                                                                countryCode: Mocks.countryCode,
                                                                cardReaderModel: Mocks.cardReaderModel,
                                                                currency: Mocks.currency,
                                                                paymentMethod: Mocks.paymentMethod)
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        analytics = nil
        analyticsProvider = nil
    }

    func test_presentSendReceiptAfterPayment_tracks_receiptEmailTapped_event_with_api_source() throws {
        // When
        coordinator.presentSendReceiptAfterPayment(from: MockViewControllerPresenting(), order: .fake()) { _ in }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "receipt_email_tapped" }))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, "CHIPPER_2X")
        XCTAssertEqual(eventProperties["country"] as? String, "CA")
        XCTAssertEqual(eventProperties["source"] as? String, "api")
        XCTAssertEqual(eventProperties["currency"] as? String, "CAD")
        XCTAssertEqual(eventProperties["payment_method_type"] as? String, "card")
    }
}

private extension CardPresentPaymentReceiptEmailCoordinatorTests {
    enum Mocks {
        static let countryCode = CountryCode.CA
        static let cardReaderModel = "CHIPPER_2X"
        static let currency = "CAD"
        static let paymentMethod = PaymentMethod.card
    }
}
