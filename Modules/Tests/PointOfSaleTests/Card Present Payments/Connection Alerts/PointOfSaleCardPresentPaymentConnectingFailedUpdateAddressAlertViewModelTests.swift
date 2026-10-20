import UIKit
import TestKit
import XCTest
@testable import PointOfSale

final class PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModelTests: XCTestCase {

    func test_manual_equatable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: {},
            cancelSearchAction: {})

        XCTAssertPropertyCount(sut,
                               expectedCount: 13,
                               messageHint: "Please check that the manual equatable conformance includes new properties.")
    }

    func test_manual_hashable_conformance_number_of_properties_unchanged() {
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: {},
            cancelSearchAction: {})

        XCTAssertPropertyCount(sut,
                               expectedCount: 13,
                               messageHint: "Please check that the manual hashable conformance includes new properties.")
    }

    func test_applicationWillEnterForeground_when_settings_opened_in_browser_then_retries_search_once() throws {
        // Given
        var openedURLs: [URL] = []
        let notificationCenter = NotificationCenter()
        var retryCount = 0
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: false,
            retrySearchAction: { retryCount += 1 },
            cancelSearchAction: {},
            openURL: { openedURLs.append($0) },
            notificationCenter: notificationCenter)
        try XCTUnwrap(sut.primaryButtonViewModel).actionHandler()

        // When
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // Then
        XCTAssertEqual(openedURLs, [URL(string: "https://example.com")!])
        XCTAssertEqual(retryCount, 1)
    }

    func test_applicationWillEnterForeground_when_settings_not_opened_then_does_not_retry_search() {
        // Given
        let notificationCenter = NotificationCenter()
        var retryCount = 0
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: false,
            retrySearchAction: { retryCount += 1 },
            cancelSearchAction: {},
            openURL: { _ in },
            notificationCenter: notificationCenter)

        // When
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // Then
        XCTAssertEqual(retryCount, 0)
        withExtendedLifetime(sut) {}
    }

    func test_applicationWillEnterForeground_when_settings_opened_in_authenticated_web_view_then_does_not_retry_search() throws {
        // Given
        let notificationCenter = NotificationCenter()
        var retryCount = 0
        let sut = PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: true,
            retrySearchAction: { retryCount += 1 },
            cancelSearchAction: {},
            openURL: { _ in },
            notificationCenter: notificationCenter)
        try XCTUnwrap(sut.primaryButtonViewModel).actionHandler()

        // When
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // Then
        XCTAssertTrue(sut.shouldShowSettingsWebView)
        XCTAssertEqual(retryCount, 0)
    }

    func test_applicationWillEnterForeground_when_alert_released_then_does_not_retry_search() throws {
        // Given
        let notificationCenter = NotificationCenter()
        var retryCount = 0
        var sut: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel? = .init(
            settingsAdminUrl: URL(string: "https://example.com")!,
            showsInAuthenticatedWebView: false,
            retrySearchAction: { retryCount += 1 },
            cancelSearchAction: {},
            openURL: { _ in },
            notificationCenter: notificationCenter)
        try XCTUnwrap(sut?.primaryButtonViewModel).actionHandler()
        weak var releasedViewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel?
        releasedViewModel = sut

        // When
        sut = nil
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // Then
        XCTAssertNil(releasedViewModel)
        XCTAssertEqual(retryCount, 0)
    }
}
