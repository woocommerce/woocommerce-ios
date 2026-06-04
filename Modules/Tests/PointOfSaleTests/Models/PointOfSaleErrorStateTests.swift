import Foundation
import Testing
import enum NetworkingCore.POSCatalogFileError
@testable import PointOfSale

struct PointOfSaleErrorStateTests {
    @Test func errorOnRefreshingCatalog_when_catalog_file_download_fails_then_shows_server_permissions_subtitle() {
        // Given
        let error = POSCatalogFileError.downloadFailed(
            statusCode: 403,
            contentType: "text/html; charset=UTF-8",
            underlyingError: NSError(domain: "Test", code: 403)
        )

        // When
        let errorState = PointOfSaleErrorState.errorOnRefreshingCatalog(error: error)

        // Then
        #expect(errorState.subtitle == catalogFileResponseErrorSubtitle)
    }

    @Test func errorOnRefreshingCatalog_when_catalog_file_response_is_invalid_then_shows_server_permissions_subtitle() {
        // Given
        let error = POSCatalogFileError.invalidResponse(
            statusCode: 200,
            contentType: "text/html",
            underlyingError: NSError(domain: "Test", code: 0)
        )

        // When
        let errorState = PointOfSaleErrorState.errorOnRefreshingCatalog(error: error)

        // Then
        #expect(errorState.subtitle == catalogFileResponseErrorSubtitle)
    }

    @Test func errorOnRefreshingCatalog_when_connectivity_error_then_shows_connectivity_subtitle() {
        // Given
        let error = URLError(.notConnectedToInternet)

        // When
        let errorState = PointOfSaleErrorState.errorOnRefreshingCatalog(error: error)

        // Then
        #expect(errorState.subtitle == "Please check your internet connection and try again.")
    }

    @Test func errorOnRefreshingCatalog_when_generic_error_then_shows_generic_subtitle() {
        // Given
        let error = NSError(domain: "Test", code: 0)

        // When
        let errorState = PointOfSaleErrorState.errorOnRefreshingCatalog(error: error)

        // Then
        #expect(errorState.subtitle == "Please try again.")
    }
}

private let catalogFileResponseErrorSubtitle = "The catalog file could not be downloaded from your store due blocked server permissions. " +
"Please contact your hosting provider."
