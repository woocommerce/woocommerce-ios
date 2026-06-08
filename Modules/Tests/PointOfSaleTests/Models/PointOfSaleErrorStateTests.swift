import Foundation
import Testing
import enum Networking.BackgroundDownloadError
import enum NetworkingCore.POSCatalogFileError
@testable import PointOfSale

struct PointOfSaleErrorStateTests {
    @Test
    func errorOnLoadingOrders_uses_try_again_button_text() {
        let errorState = PointOfSaleErrorState.errorOnLoadingOrders()

        #expect(errorState.buttonText == "Try again")
    }

    @Test
    func errorOnLoadingOrdersNextPage_uses_try_again_button_text() {
        let errorState = PointOfSaleErrorState.errorOnLoadingOrdersNextPage()

        #expect(errorState.buttonText == "Try again")
    }

    @Test
    func errorOnLoadingProducts_keeps_generic_retry_button_text() {
        let errorState = PointOfSaleErrorState.errorOnLoadingProducts()

        #expect(errorState.buttonText == "Retry")
    }

    @Test func errorOnRefreshingCatalog_when_catalog_file_download_fails_then_shows_server_permissions_subtitle() {
        // Given
        let error = POSCatalogFileError.downloadFailed(
            statusCode: 403,
            contentType: "text/html; charset=UTF-8"
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

    @Test func errorOnRefreshingCatalog_when_background_download_connectivity_error_then_shows_connectivity_subtitle() {
        // Given
        let error = BackgroundDownloadError.downloadFailed(URLError(.notConnectedToInternet))

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

private let catalogFileResponseErrorSubtitle = "The catalog file could not be downloaded from your store due to blocked server permissions. " +
"Please contact your hosting provider."
