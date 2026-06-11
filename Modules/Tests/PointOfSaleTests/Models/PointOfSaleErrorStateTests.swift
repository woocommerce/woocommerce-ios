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

    @Test func errorOnRefreshingCatalog_when_catalog_file_blocked_then_shows_blocked_title_and_subtitle() {
        // Given
        let error = POSCatalogFileError.blocked(
            statusCode: 403,
            contentType: "text/html; charset=UTF-8"
        )

        // When
        let errorState = PointOfSaleErrorState.errorOnRefreshingCatalog(error: error)

        // Then
        #expect(errorState.title == catalogBlockedTitle)
        #expect(errorState.subtitle == catalogBlockedSubtitle)
    }

    @Test func errorOnInitalCatalogSync_when_catalog_file_blocked_then_shows_blocked_title_and_subtitle() {
        // Given
        let error = POSCatalogFileError.blocked(
            statusCode: 403,
            contentType: "text/html; charset=UTF-8"
        )

        // When
        let errorState = PointOfSaleErrorState.errorOnInitalCatalogSync(error: error)

        // Then
        #expect(errorState.title == catalogBlockedTitle)
        #expect(errorState.subtitle == catalogBlockedSubtitle)
    }

    @Test func errorOnRefreshingCatalog_when_catalog_file_download_fails_then_shows_generic_subtitle() {
        // Given
        let error = POSCatalogFileError.downloadFailed(
            statusCode: 404,
            contentType: nil
        )

        // When
        let errorState = PointOfSaleErrorState.errorOnRefreshingCatalog(error: error)

        // Then
        #expect(errorState.title == "Unable to refresh catalog")
        #expect(errorState.subtitle == "Please try again.")
    }

    @Test func errorOnRefreshingCatalog_when_catalog_file_response_is_invalid_then_shows_generic_subtitle() {
        // Given
        let error = POSCatalogFileError.invalidResponse(
            statusCode: 200,
            contentType: "text/html",
            underlyingError: NSError(domain: "Test", code: 0)
        )

        // When
        let errorState = PointOfSaleErrorState.errorOnRefreshingCatalog(error: error)

        // Then
        #expect(errorState.subtitle == "Please try again.")
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

private let catalogBlockedTitle = "Action needed on your store"
private let catalogBlockedSubtitle = "Point of Sale can't access a file with your product information because your hosting provider is blocking it. " +
"Please ask them to allow access to it so Point of Sale keeps working properly."
