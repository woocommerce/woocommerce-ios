import UIKit
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
struct ApplicationPasswordAuthorizationViewModelTests {
    @Test func test_authorization_failure_when_alert_is_presented_then_tracks_app_password_flow() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let failure = UnexpectedStoreResponseError(kind: .unacceptableStatusCode, statusCode: 500)
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            if case let .fetchApplicationPasswordAuthorizationURL(_, _, completion) = action {
                completion(.failure(failure))
            }
        }
        let provider = MockAnalyticsProvider()
        let model = ApplicationPasswordAuthorizationViewModel(siteURL: "https://example.com", stores: stores)
        let controller = ApplicationPasswordAuthorizationWebViewController(viewModel: model, previousViewController: nil,
                                                                           analytics: WooAnalytics(analyticsProvider: provider)) { _, _ in }
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        defer { window.isHidden = true }
        let event = WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue
        // When
        #expect(!provider.receivedEvents.contains(event))
        window.makeKeyAndVisible()
        let deadline = ContinuousClock.now.advanced(by: .seconds(5))
        while !provider.receivedEvents.contains(event), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        // Then
        #expect(controller.presentedViewController is UIAlertController)
        #expect(provider.receivedEvents.filter { $0 == event }.count == 1)
        #expect(provider.receivedProperties.last?["login_flow"] as? String == "app_password")
        #expect(provider.receivedProperties.last?["step"] as? String == "app_password_authorization_url")
        #expect(provider.receivedProperties.last?["failure_kind"] as? String == "unacceptable_status_code")
    }

    @Test func test_authorization_when_unexpected_response_occurs_then_preserves_failure() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let failure = UnexpectedStoreResponseError(kind: .unexpectedContent)
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            if case let .fetchApplicationPasswordAuthorizationURL(_, enabled, completion) = action {
                #expect(enabled)
                completion(.failure(failure))
            }
        }
        let model = ApplicationPasswordAuthorizationViewModel(siteURL: "https://example.com", stores: stores)
        // When
        do {
            _ = try await model.fetchAuthURL()
            Issue.record("Expected an unexpected response")
        } catch {
            // Then
            #expect(error as? UnexpectedStoreResponseError == failure)
            #expect(LoginUnexpectedResponseFailure(error: error, step: .appPasswordAuthorizationURL)?.step == .appPasswordAuthorizationURL)
        }
    }
}
