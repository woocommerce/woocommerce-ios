import UIKit
import Testing
import Yosemite
@testable import WooCommerce

@MainActor
@Suite(.timeLimit(.minutes(5)))
struct ApplicationPasswordAuthorizationViewModelTests {
    @Test func test_authorization_failure_when_alert_is_presented_then_tracks_app_password_flow() async {
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
        let event = WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue
        var presentedAlert: UIAlertController?
        var presentationCompletion: (() -> Void)?
        var controller: ApplicationPasswordAuthorizationWebViewController?

        // When: wait for the presentation request, without a key window or animation.
        await withCheckedContinuation { continuation in
            controller = ApplicationPasswordAuthorizationWebViewController(
                viewModel: model,
                previousViewController: nil,
                analytics: WooAnalytics(analyticsProvider: provider),
                alertPresenter: { _, alert, completion in
                    presentedAlert = alert
                    presentationCompletion = completion
                    continuation.resume()
                },
                onSuccess: { _, _ in }
            )
            controller?.loadViewIfNeeded()
        }

        // Then: tracking waits for presentation to complete.
        #expect(presentedAlert != nil)
        #expect(!provider.receivedEvents.contains(event))
        withExtendedLifetime(controller) {
            presentationCompletion?()
        }
        #expect(provider.receivedEvents.filter { $0 == event }.count == 1)
        #expect(provider.receivedProperties.last?["login_flow"] as? String == "app_password")
        #expect(provider.receivedProperties.last?["step"] as? String == "app_password_authorization_url")
        #expect(provider.receivedProperties.last?["failure_kind"] as? String == "unacceptable_status_code")
    }

    @Test(arguments: [true, false])
    func test_authorization_retry_when_fetch_completes_then_tracks_once_and_refetches_same_site(success: Bool) async {
        // Given
        let fixture = AuthorizationFixture()
        await fixture.start()
        fixture.completeFetch?(.failure(UnexpectedStoreResponseError(kind: .unexpectedContent)))
        await fixture.waitForFetchHandling()
        fixture.presentationCompletion?()

        // When
        await fixture.waitForFetch {
            fixture.controller.unexpectedResponsePresenter.select(.retry)
            fixture.controller.unexpectedResponsePresenter.select(.retry)
        }
        fixture.completeFetch?(success ? .success(URL(string: "https://example.com/authorize")) :
                                 .failure(UnexpectedStoreResponseError(kind: .unexpectedContent)))
        await fixture.waitForFetchHandling()

        // Then
        let event = WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue
        #expect(fixture.requestedSites == ["https://example.com", "https://example.com"])
        #expect(fixture.provider.receivedEvents.filter { $0 == event }.count == 1)
        #expect(fixture.provider.properties(for: event)?["result"] as? String == (success ? "success" : "failure"))
        #expect(fixture.provider.properties(for: event)?["step"] as? String == "app_password_authorization_url")
        #expect(fixture.alert?.actions.map(\.title) == ["Try Again", "Contact Support", "Dismiss"])
    }

    @Test func test_authorization_retry_when_screen_is_removed_then_ignores_stale_callback() async {
        // Given
        let fixture = AuthorizationFixture()
        await fixture.start()
        fixture.completeFetch?(.failure(UnexpectedStoreResponseError(kind: .unexpectedContent)))
        await fixture.waitForFetchHandling()
        await fixture.waitForFetch { fixture.controller.unexpectedResponsePresenter.select(.retry) }
        let staleCompletion = fixture.completeFetch

        // When
        fixture.navigation.popViewController(animated: false)
        staleCompletion?(.failure(UnexpectedStoreResponseError(kind: .unexpectedContent)))
        // Allow the cancelled task to process its continuation.
        await fixture.controller.authorizationTask?.value

        // Then
        #expect(fixture.cancelCount == 1)
        #expect(fixture.alertCount == 1)
        #expect(!fixture.provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))
    }

    @Test(arguments: [LoginUnexpectedResponseFailure.Action.dismiss, .contactSupport])
    func test_authorization_action_when_selected_then_restores_same_form_and_opens_support_directly(action: LoginUnexpectedResponseFailure.Action) async {
        // Given
        let fixture = AuthorizationFixture()
        await fixture.start()
        fixture.completeFetch?(.failure(UnexpectedStoreResponseError(kind: .unexpectedContent)))
        await fixture.waitForFetchHandling()

        // When
        fixture.controller.unexpectedResponsePresenter.select(action)

        // Then
        #expect(fixture.navigation.viewControllers.first === fixture.form)
        #expect(fixture.navigation.viewControllers.count == (action == .dismiss ? 1 : 2))
        if action == .contactSupport {
            let host = fixture.navigation.topViewController as? SupportChatHostingController
            #expect(host != nil)
            #expect(host?.rootView.viewModel.supportSiteAddress == "https://example.com")
        }
        #expect(!fixture.provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))
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

@MainActor
private final class AuthorizationFixture {
    let stores = MockStoresManager(sessionManager: .makeForTesting())
    let provider = MockAnalyticsProvider()
    let form = UIViewController()
    lazy var navigation = UINavigationController(rootViewController: form)
    var requestedSites: [String] = []
    var completeFetch: ((Result<URL?, Error>) -> Void)?
    var fetchRequested: (() -> Void)?
    var alert: UIAlertController?
    var presentationCompletion: (() -> Void)?
    var alertCount = 0
    var cancelCount = 0
    lazy var controller = ApplicationPasswordAuthorizationWebViewController(
        viewModel: .init(siteURL: "https://example.com", stores: stores), previousViewController: form,
        analytics: WooAnalytics(analyticsProvider: provider), alertPresenter: { [weak self] _, alert, completion in
            self?.alert = alert
            self?.presentationCompletion = completion
            self?.alertCount += 1
        }, onCancel: { [weak self] in self?.cancelCount += 1 }, onSuccess: { _, _ in })

    init() {
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { [weak self] action in
            guard let self, case let .fetchApplicationPasswordAuthorizationURL(site, enabled, completion) = action else { return }
            #expect(enabled)
            requestedSites.append(site)
            completeFetch = completion
            let callback = fetchRequested
            fetchRequested = nil
            callback?()
        }
    }

    func start() async {
        navigation.loadViewIfNeeded()
        navigation.view.layoutIfNeeded()
        await waitForFetch {
            navigation.pushViewController(controller, animated: false)
            controller.loadViewIfNeeded()
        }
    }

    func waitForFetch(action: () -> Void) async {
        await withCheckedContinuation { continuation in
            fetchRequested = { continuation.resume() }
            action()
        }
    }

    func waitForFetchHandling() async {
        await controller.authorizationTask?.value
    }
}
