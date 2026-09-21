import Foundation
import Testing
import GRDB
import Alamofire
import enum Networking.BackgroundDownloadError
import NetworkingCore
@testable import Yosemite

struct POSCatalogSyncErrorClassifierTests {
    @Test func classify_database_full_error_returns_insufficient_space() {
        // Given
        let error = DatabaseError(resultCode: .SQLITE_FULL)

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "insufficient_free_space")
    }

    @Test func classify_database_corrupt_error_returns_database_corruption() {
        // Given
        let error = DatabaseError(resultCode: .SQLITE_CORRUPT)

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "database_corruption")
    }

    @Test func classify_database_constraint_error_returns_constraint_violation() {
        // Given
        let error = DatabaseError(resultCode: .SQLITE_CONSTRAINT)

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "database_constraint_violation")
    }

    @Test func classify_database_io_error_returns_database_error() {
        // Given
        let error = DatabaseError(resultCode: .SQLITE_IOERR)

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "database_error")
    }

    @Test func classify_cancellation_error_returns_request_cancelled() {
        // Given
        let error = CancellationError()

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "request_cancelled")
    }

    @Test func classify_url_error_not_connected_returns_network_error() {
        // Given
        let error = URLError(.notConnectedToInternet)

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "network_error")
    }

    @Test func classify_url_error_timeout_returns_network_timeout() {
        // Given
        let error = URLError(.timedOut)

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "network_timeout")
    }

    @Test func classify_decoding_error_returns_catalog_integrity() {
        // Given
        struct TestModel: Decodable {
            let field: String
        }
        let jsonData = Data("{}".utf8)
        let decoder = JSONDecoder()
        var decodingError: Error?
        do {
            _ = try decoder.decode(TestModel.self, from: jsonData)
        } catch {
            decodingError = error
        }

        // When
        let result = POSCatalogSyncErrorClassifier.classify(decodingError!)

        // Then
        #expect(result == "catalog_integrity")
    }

    @Test func classify_catalog_file_download_error_returns_catalog_file_download_failed() {
        // Given: a non-blocked download failure (404, no HTML markers)
        let error = POSCatalogFileError.downloadFailed(statusCode: 404,
                                                       contentType: "application/json")

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "catalog_file_download_failed")
    }

    @Test func classify_blocked_download_returns_catalog_file_blocked() {
        // Given: a 403 with an HTML error page — the host blocks the catalog file
        let error = POSCatalogFileError.downloadFailed(statusCode: 403,
                                                       contentType: "text/html; charset=UTF-8")

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then: classified as blocked, not the 403 authentication fallback
        #expect(result == "catalog_file_blocked")
    }

    @Test func classify_blocked_invalid_response_returns_catalog_file_blocked() {
        // Given: a 2xx response whose body is HTML instead of the catalog JSON
        let error = POSCatalogFileError.invalidResponse(statusCode: 200,
                                                        contentType: "application/json",
                                                        hasHTMLBody: true,
                                                        underlyingError: NSError(domain: "Test", code: 0))

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "catalog_file_blocked")
    }

    @Test func classify_catalog_file_invalid_response_error_returns_catalog_file_invalid_response() {
        // Given: an unparseable body without HTML markers
        let error = POSCatalogFileError.invalidResponse(statusCode: 200,
                                                        contentType: "application/json",
                                                        hasHTMLBody: false,
                                                        underlyingError: NSError(domain: "Test", code: 0))

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "catalog_file_invalid_response")
    }

    @Test func classify_authentication_error_returns_authentication_error() {
        // Given
        let error = NSError(domain: "Test", code: 401, userInfo: nil)

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "authentication_error")
    }

    @Test func classify_unknown_error_returns_unexpected_error() {
        // Given
        struct CustomError: Error {}
        let error = CustomError()

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "unexpected_error")
    }

    @Test func classify_afError_wrapping_url_error_returns_network_error() {
        // Given
        let urlError = URLError(.notConnectedToInternet)
        let afError = AFError.sessionTaskFailed(error: urlError)

        // When
        let result = POSCatalogSyncErrorClassifier.classify(afError)

        // Then
        #expect(result == "network_error")
    }

    @Test func classify_background_download_error_wrapping_url_error_returns_network_error() {
        // Given
        let error = BackgroundDownloadError.downloadFailed(URLError(.notConnectedToInternet))

        // When
        let result = POSCatalogSyncErrorClassifier.classify(error)

        // Then
        #expect(result == "network_error")
    }

    @Test func classify_afError_with_401_status_returns_authentication_error() {
        // Given
        let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))

        // When
        let result = POSCatalogSyncErrorClassifier.classify(afError)

        // Then
        #expect(result == "authentication_error")
    }
}
