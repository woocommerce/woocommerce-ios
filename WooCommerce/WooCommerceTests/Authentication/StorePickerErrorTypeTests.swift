import Foundation
import Testing
import enum NetworkingCore.DotcomError
import struct NetworkingCore.AnyDecodable
@testable import WooCommerce

@Suite("StorePickerErrorType")
struct StorePickerErrorTypeTests {

    @Test func from_when_DotcomError_requestFailed_then_returns_serverError() {
        // Given
        let error: Error = DotcomError.requestFailed()

        // When
        let errorType = StorePickerErrorType.from(error)

        // Then
        #expect(errorType == .serverError)
    }

    @Test func from_when_other_error_then_returns_generic() {
        // Given
        let error: Error = URLError(.notConnectedToInternet)

        // When
        let errorType = StorePickerErrorType.from(error)

        // Then
        #expect(errorType == .generic)
    }

    @Test func technicalDetails_when_requestFailed_with_data_then_returns_compact_summary() {
        // Given
        let data: [String: AnyDecodable] = [
            "status": AnyDecodable(500),
            "errors": AnyDecodable([
                "code": "http_request_failed",
                "message": "cURL error 28: Operation timed out"
            ] as [String: String])
        ]
        let error: Error = DotcomError.requestFailed(data: data)

        // When
        let details = StorePickerErrorType.technicalDetails(from: error)

        // Then
        #expect(details == "Status: 500\nError: http_request_failed\ncURL error 28: Operation timed out")
    }

    @Test func technicalDetails_when_non_DotcomError_then_returns_nil() {
        // Given
        let error: Error = URLError(.notConnectedToInternet)

        // When
        let details = StorePickerErrorType.technicalDetails(from: error)

        // Then
        #expect(details == nil)
    }
}
