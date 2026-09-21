import Testing
import Alamofire
import Foundation
@testable import Networking
@testable import WooCommerce

struct ErrorErrorCodeTests {

    // MARK: - errorCode Tests

    @Test func errorCode_when_NetworkError_with_responseCode_then_returns_responseCode() {
        // Given
        let error: Error = NetworkError.unacceptableStatusCode(statusCode: 401, response: nil)

        // Then
        #expect(error.errorCode == 401)
    }

    @Test func errorCode_when_DotcomError_with_status_in_data_then_returns_status() {
        // Given
        let error: Error = DotcomError.unknown(code: "error", message: "message", data: ["status": AnyDecodable(403)])

        // Then
        #expect(error.errorCode == 403)
    }

    @Test func errorCode_when_AFError_with_responseCode_then_returns_responseCode() {
        // Given
        let error: Error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403))

        // Then
        #expect(error.errorCode == 403)
    }

    @Test func errorCode_when_AFError_with_underlyingError_then_returns_underlyingErrorCode() {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 500)
        let error: Error = AFError.sessionTaskFailed(error: underlyingError)

        // Then
        #expect(error.errorCode == 500)
    }

    @Test func errorCode_when_plain_NSError_then_returns_NSError_code() {
        // Given
        let error: Error = NSError(domain: "TestDomain", code: 123)

        // Then
        #expect(error.errorCode == 123)
    }

    // MARK: - errorDomain Tests

    @Test func errorDomain_when_AFError_with_underlyingError_then_returns_underlyingErrorDomain() {
        // Given
        let underlyingError = NSError(domain: "UnderlyingDomain", code: 500)
        let error: Error = AFError.sessionTaskFailed(error: underlyingError)

        // Then
        #expect(error.errorDomain == "UnderlyingDomain")
    }

    @Test func errorDomain_when_plain_NSError_then_returns_NSError_domain() {
        // Given
        let error: Error = NSError(domain: "TestDomain", code: 123)

        // Then
        #expect(error.errorDomain == "TestDomain")
    }

    // MARK: - formattedTechnicalDetails Tests

    @Test func formattedTechnicalDetails_includes_errorCode_and_domain() {
        // Given
        let error: Error = NSError(domain: "TestDomain", code: 404)

        // When
        let details = error.formattedTechnicalDetails

        // Then
        #expect(details.contains("Error Code: 404"))
        #expect(details.contains("Domain: TestDomain"))
    }

    // MARK: - SiteCredentialLoginError Tests

    @Test func errorCode_when_SiteCredentialLoginError_invalidCredentials_then_returns_401() {
        // Given
        let error: Error = SiteCredentialLoginError.invalidCredentials

        // Then
        #expect(error.errorCode == 401)
    }

    @Test func errorCode_when_SiteCredentialLoginError_inaccessibleLoginPage_then_returns_404() {
        // Given
        let error: Error = SiteCredentialLoginError.inaccessibleLoginPage

        // Then
        #expect(error.errorCode == 404)
    }

    @Test func errorCode_when_SiteCredentialLoginError_unacceptableStatusCode_then_returns_code() {
        // Given
        let error: Error = SiteCredentialLoginError.unacceptableStatusCode(code: 500)

        // Then
        #expect(error.errorCode == 500)
    }

    @Test func errorCode_when_SiteCredentialLoginError_genericFailure_then_returns_underlyingErrorCode() {
        // Given
        let underlyingError = NSError(domain: "TestDomain", code: 503)
        let error: Error = SiteCredentialLoginError.genericFailure(underlyingError: underlyingError)

        // Then
        #expect(error.errorCode == 503)
    }
}
