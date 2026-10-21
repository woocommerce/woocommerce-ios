import XCTest
@testable import PointOfSale

final class PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModelTests: XCTestCase {
    func test_enterAddress_when_authenticated_webview_is_used_then_shows_settings_and_offers_retry() throws {
        // Given
        var retryCount = 0
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: { retryCount += 1 },
            cancelSearchAction: {})
        XCTAssertFalse(sut.shouldShowSettingsWebView)

        // When
        try XCTUnwrap(sut.primaryButtonViewModel).actionHandler()

        // Then
        XCTAssertTrue(sut.shouldShowSettingsWebView)
        XCTAssertEqual(sut.primaryButtonViewModel?.title, "Retry After Updating")
        XCTAssertEqual(retryCount, 0)

        // When the merchant retries after updating the address
        try XCTUnwrap(sut.primaryButtonViewModel).actionHandler()

        // Then
        XCTAssertEqual(retryCount, 1)
    }

    func test_settingsWebViewWasDismissed_when_address_editing_ends_then_retries_reader_search() {
        // Given
        var retryCount = 0
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: { retryCount += 1 },
            cancelSearchAction: {})

        // When
        sut.settingsWebViewWasDismissed()

        // Then
        XCTAssertEqual(retryCount, 1)
    }
}
