import XCTest
@testable import WooCommerce

final class CardPresentPaymentReceiptEmailCoordinatorTests: XCTestCase {
    private var coordinator: CardPresentPaymentReceiptEmailCoordinator!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        coordinator = CardPresentPaymentReceiptEmailCoordinator(analytics: analytics, countryCode: Mocks.countryCode, cardReaderModel: Mocks.cardReaderModel)
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        analytics = nil
        analyticsProvider = nil
    }

    func test_presentEmailForm_with_failure_tracks_receiptEmailFailed_event() throws {
        // When
        let _: Void = waitFor { promise in
            self.coordinator.presentEmailForm(data: .init(content: "", order: .fake(), storeName: nil),
                                              from: .init()) {
                promise(())
            }
            let error = NSError(domain: "Email receipt failure", code: 100, userInfo: [:])
            self.coordinator.mailComposeController(.init(), didFinishWith: .failed, error: error)
        }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "receipt_email_failed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, "CHIPPER_2X")
        XCTAssertEqual(eventProperties["country"] as? String, "CA")
        XCTAssertEqual(eventProperties["error_code"] as? String, "100")
        XCTAssertEqual(eventProperties["error_domain"] as? String, "Email receipt failure")
    }

    func test_presentEmailForm_with_nil_cardReaderModel_and_failure_tracks_receiptEmailFailed_event_without_cardReaderModel_prop() throws {
        // Given
        let coordinator = CardPresentPaymentReceiptEmailCoordinator(analytics: analytics, countryCode: Mocks.countryCode, cardReaderModel: nil)

        // When
        let _: Void = waitFor { promise in
            coordinator.presentEmailForm(data: .init(content: "", order: .fake(), storeName: nil),
                                              from: .init()) {
                promise(())
            }
            let error = NSError(domain: "Email receipt failure", code: 100, userInfo: [:])
            coordinator.mailComposeController(.init(), didFinishWith: .failed, error: error)
        }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "receipt_email_failed"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertNil(eventProperties["card_reader_model"])
        XCTAssertEqual(eventProperties["country"] as? String, "CA")
        XCTAssertEqual(eventProperties["error_code"] as? String, "100")
        XCTAssertEqual(eventProperties["error_domain"] as? String, "Email receipt failure")
    }

    func test_canceling_email_form_tracks_receiptEmailCanceled_event() throws {
        // When
        let _: Void = waitFor { promise in
            self.coordinator.presentEmailForm(data: .init(content: "", order: .fake(), storeName: nil),
                                              from: .init()) {
                promise(())
            }
            self.coordinator.mailComposeController(.init(), didFinishWith: .cancelled, error: nil)
        }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "receipt_email_canceled"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, "CHIPPER_2X")
        XCTAssertEqual(eventProperties["country"] as? String, "CA")
    }

    func test_sending_email_successfully_tracks_receiptEmailSuccess_event() throws {
        // When
        let _: Void = waitFor { promise in
            self.coordinator.presentEmailForm(data: .init(content: "", order: .fake(), storeName: nil),
                                              from: .init()) {
                promise(())
            }
            self.coordinator.mailComposeController(.init(), didFinishWith: .sent, error: nil)
        }

        // Then
        let indexOfEvent = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == "receipt_email_success"}))
        let eventProperties = try XCTUnwrap(analyticsProvider.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["card_reader_model"] as? String, "CHIPPER_2X")
        XCTAssertEqual(eventProperties["country"] as? String, "CA")
    }
}

private extension CardPresentPaymentReceiptEmailCoordinatorTests {
    enum Mocks {
        static let countryCode = "CA"
        static let cardReaderModel = "CHIPPER_2X"
    }
}
