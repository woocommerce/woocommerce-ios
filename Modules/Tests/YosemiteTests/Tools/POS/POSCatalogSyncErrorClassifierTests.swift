import Foundation
import Testing
import GRDB
import Alamofire
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

    @Test func classify_afError_with_401_status_returns_authentication_error() {
        // Given
        let afError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))

        // When
        let result = POSCatalogSyncErrorClassifier.classify(afError)

        // Then
        #expect(result == "authentication_error")
    }
}
