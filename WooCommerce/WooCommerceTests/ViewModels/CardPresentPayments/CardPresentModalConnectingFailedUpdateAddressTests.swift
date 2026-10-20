import Foundation
import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct CardPresentModalConnectingFailedUpdateAddressTests {
    @Test func willEnterForeground_when_retry_variant_is_shown_then_retries_search_once() {
        // Given
        let notificationCenter = NotificationCenter()
        var retryCount = 0
        let viewModel = CardPresentModalConnectingFailedUpdateAddress(wcSettingsAdminURL: nil,
                                                                      openWCSettings: nil,
                                                                      retrySearch: { retryCount += 1 },
                                                                      cancelSearch: {},
                                                                      notificationCenter: notificationCenter)

        // When
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // Then
        #expect(retryCount == 1)
        withExtendedLifetime(viewModel) {}
    }

    @Test func willEnterForeground_when_enter_address_variant_is_shown_then_does_not_retry_search() {
        // Given
        let notificationCenter = NotificationCenter()
        var retryCount = 0
        let viewModel = CardPresentModalConnectingFailedUpdateAddress(wcSettingsAdminURL: URL(string: "https://example.com"),
                                                                      openWCSettings: {},
                                                                      retrySearch: { retryCount += 1 },
                                                                      cancelSearch: {},
                                                                      notificationCenter: notificationCenter)

        // When
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // Then
        #expect(retryCount == 0)
        withExtendedLifetime(viewModel) {}
    }

    @Test func willEnterForeground_when_alert_was_replaced_then_does_not_retry_search() {
        // Given
        let notificationCenter = NotificationCenter()
        var retryCount = 0
        var viewModel: CardPresentModalConnectingFailedUpdateAddress? = CardPresentModalConnectingFailedUpdateAddress(
            wcSettingsAdminURL: nil,
            openWCSettings: nil,
            retrySearch: { retryCount += 1 },
            cancelSearch: {},
            notificationCenter: notificationCenter)
        #expect(viewModel != nil)

        // When
        viewModel = nil
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        // Then
        #expect(retryCount == 0)
    }
}
