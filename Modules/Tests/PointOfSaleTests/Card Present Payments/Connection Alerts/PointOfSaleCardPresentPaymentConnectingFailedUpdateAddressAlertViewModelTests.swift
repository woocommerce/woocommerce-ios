import Foundation
import TestKit
import XCTest
@testable import PointOfSale

final class PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModelTests: XCTestCase {

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            retrySearchAction: {},
            cancelSearchAction: {})

        XCTAssertPropertyCount(sut,
                               expectedCount: 9,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }

    func test_manual_hashable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            retrySearchAction: {},
            cancelSearchAction: {})

        XCTAssertPropertyCount(sut,
                               expectedCount: 9,
                               messageHint: "Please check that the manual hashable conformance includes new properties.")
    }

    func test_enter_address_when_tapped_then_opens_settings_and_offers_retry() {
        // Given
        var retryCount = 0
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            retrySearchAction: { retryCount += 1 },
            cancelSearchAction: {})
        let enterAddressTitle = sut.primaryButtonViewModel.title

        // When
        sut.primaryButtonViewModel.actionHandler()

        // Then
        XCTAssertTrue(sut.shouldShowSettingsWebView)
        XCTAssertNotEqual(sut.primaryButtonViewModel.title, enterAddressTitle)
        XCTAssertEqual(retryCount, 0)
    }

    func test_settings_web_view_when_dismissed_then_retries_reader_search() {
        // Given
        var retryCount = 0
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            retrySearchAction: { retryCount += 1 },
            cancelSearchAction: {})
        sut.primaryButtonViewModel.actionHandler()

        // When
        sut.settingsWebViewWasDismissed()

        // Then
        XCTAssertEqual(retryCount, 1)
    }
}
