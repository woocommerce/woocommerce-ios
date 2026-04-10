import Testing
import enum NetworkingCore.DotcomError
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
}
