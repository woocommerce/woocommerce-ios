@testable import PointOfSale
import XCTest
@testable import WooCommerce
import Yosemite

final class POSRefundCardPresentPaymentAlertsTests: XCTestCase {
    @MainActor
    func test_present_when_payment_cancellation_runs_then_marks_refund_as_cancelled() {
        let stateModel = POSRefundSubmissionModel()
        var didMarkCancelled = false
        var didCancelPayment = false
        let sut = POSRefundCardPresentPaymentAlertsPresenter(stateModel: stateModel) {
            didMarkCancelled = true
        }

        sut.present(viewModel: .tapSwipeOrInsertCard(inputMethods: [.tap, .insert]) {
            didCancelPayment = true
        })

        guard case .tapSwipeOrInsertCard(_, let cancelPayment) = cardPresentEvent(in: stateModel) else {
            return XCTFail("Expected tap, swipe, or insert card event.")
        }
        cancelPayment()

        XCTAssertTrue(didMarkCancelled)
        XCTAssertTrue(didCancelPayment)
    }

    @MainActor
    func test_present_when_multiple_reader_search_is_cancelled_then_marks_refund_as_cancelled() {
        let stateModel = POSRefundSubmissionModel()
        var didMarkCancelled = false
        var selectedReaderID: String?
        let sut = POSRefundCardPresentPaymentAlertsPresenter(stateModel: stateModel) {
            didMarkCancelled = true
        }

        sut.foundSeveralReaders(readerIDs: ["reader-1"]) { readerID in
            selectedReaderID = readerID
        } cancelSearch: {
            selectedReaderID = nil
        }

        guard case .foundMultipleReaders(_, let selectionHandler) = cardPresentEvent(in: stateModel) else {
            return XCTFail("Expected multiple reader event.")
        }
        selectionHandler(nil)

        XCTAssertTrue(didMarkCancelled)
        XCTAssertNil(selectedReaderID)
    }

    @MainActor
    func test_present_when_multiple_reader_is_selected_then_does_not_mark_refund_as_cancelled() {
        let stateModel = POSRefundSubmissionModel()
        var didMarkCancelled = false
        var selectedReaderID: String?
        let sut = POSRefundCardPresentPaymentAlertsPresenter(stateModel: stateModel) {
            didMarkCancelled = true
        }

        sut.foundSeveralReaders(readerIDs: ["reader-1"]) { readerID in
            selectedReaderID = readerID
        } cancelSearch: {
            selectedReaderID = nil
        }

        guard case .foundMultipleReaders(_, let selectionHandler) = cardPresentEvent(in: stateModel) else {
            return XCTFail("Expected multiple reader event.")
        }
        selectionHandler("reader-1")

        XCTAssertFalse(didMarkCancelled)
        XCTAssertEqual(selectedReaderID, "reader-1")
    }
}

private extension POSRefundCardPresentPaymentAlertsTests {
    /// The presenter updates the state model synchronously when called on the main thread.
    @MainActor
    func cardPresentEvent(in stateModel: POSRefundSubmissionModel) -> CardPresentPaymentEventDetails? {
        guard case .cardPresentEvent(let details) = stateModel.state else {
            return nil
        }
        return details
    }
}
