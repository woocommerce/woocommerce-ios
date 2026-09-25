import Foundation
import Testing
@testable import PointOfSale

struct POSCashSessionErrorMessageTests {
    @Test(arguments: [
        (POSCashSessionErrorMessage.Operation.loadCurrent, "Could not load the current cash session. Try again."),
        (.loadPast, "Could not load past cash sessions. Try again."),
        (.loadMorePast, "Could not load more cash sessions. Try again."),
        (.loadDetail, "Could not load the cash session details. Try again."),
        (.start, "Could not start the cash session. Try again."),
        (.record, "Could not record the cash adjustment. Try again."),
        (.close, "Could not close the cash session. Try again.")
    ])
    func test_message_when_unknown_error_then_explains_failed_operation(operation: POSCashSessionErrorMessage.Operation, expected: String) {
        // Given
        let error = NSError(domain: "NetworkingCore.NetworkError", code: 403,
                            userInfo: [NSLocalizedDescriptionKey: "Internal server response"])

        // When
        let message = POSCashSessionErrorMessage.message(for: error, operation: operation)

        // Then
        #expect(message == expected)
    }

    @Test(arguments: POSCashSessionErrorMessage.Operation.allCases)
    func test_message_when_unrecognized_localized_error_then_does_not_expose_its_description(operation: POSCashSessionErrorMessage.Operation) {
        // Given
        let error = ServerError()
        let genericError = NSError(domain: "test", code: 1)

        // When
        let message = POSCashSessionErrorMessage.message(for: error, operation: operation)

        // Then
        #expect(message == POSCashSessionErrorMessage.message(for: genericError, operation: operation))
        #expect(!message.contains("Internal server response"))
    }

    @Test(arguments: [
        POSCashSessionServiceError.unsupported,
        .sessionAlreadyOpen,
        .noOpenSession,
        .invalidAmount,
        .invalidReference,
        .previewUnavailable,
        .pendingCashMovements
    ])
    func test_message_when_known_cash_session_error_then_preserves_friendly_description(error: POSCashSessionServiceError) {
        // Given
        let expected = error.errorDescription

        // When
        let message = POSCashSessionErrorMessage.message(for: error, operation: .start)

        // Then
        #expect(message == expected)
    }

    @Test func test_message_when_session_changed_then_requests_review_and_recount() {
        // Given
        let error = POSCashSessionServiceError.sessionChanged

        // When
        let message = POSCashSessionErrorMessage.message(for: error, operation: .close)

        // Then
        #expect(message == "The session changed. Review the latest totals and count the cash again.")
    }

    private struct ServerError: LocalizedError {
        var errorDescription: String? { "Internal server response" }
    }
}
