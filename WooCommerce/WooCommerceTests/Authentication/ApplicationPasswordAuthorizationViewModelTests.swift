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
        let authorization = URL(string: "https://example.com/authorize").map { ApplicationPasswordAuthorization(url: $0, approvalSiteURL: nil) }
        fixture.completeFetch?(success ? .success(authorization) : .failure(UnexpectedStoreResponseError(kind: .unexpectedContent)))
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
        #expect(fixture.navigation.lastPopToViewControllerAnimated == (action == .dismiss))
        if action == .contactSupport {
            let host = fixture.navigation.topViewController as? SupportChatHostingController
            #expect(host != nil)
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

    // MARK: - Navigation decisions

    @Test(arguments: [
        "https://wordpress.com/log-in?redirect_to=https%3A%2F%2Fsite.example%2Fwp-admin%2F",
        "https://api-1234.duosecurity.com/frame/v4/auth/prompt",
        "https://site.example/wp-login.php?redirect_to=https%3A%2F%2Fsite.example%2Fwp-admin%2Fauthorize-application.php"
    ])
    func test_decision_when_login_passes_through_a_page_that_is_not_an_approval_page_then_allows(url: String) async throws {
        // Given
        let model = try await makeViewModel()

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .allow)
    }

    @Test(arguments: [
        "https://site.example/wp-admin/authorize-application.php?app_name=woo&success_url=woocommerce://application-password",
        "https://www.site.example/wp-admin/authorize-application.php?app_name=woo"
    ])
    func test_decision_when_own_approval_page_loads_then_allows(url: String) async throws {
        // Given
        let model = try await makeViewModel()

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .allow)
    }

    @Test func test_decision_when_subfolder_install_loads_its_own_approval_page_then_allows() async throws {
        // Given
        let model = try await makeViewModel(authorizationURL: "https://site.example/wp/wp-admin/authorize-application.php")

        // When
        let decision = model.decision(for: try #require(URL(string: "https://www.site.example/wp/wp-admin/authorize-application.php?app_name=woo")))

        // Then
        #expect(decision == .allow)
    }

    @Test func test_decision_when_verified_approval_site_loads_its_approval_page_then_allows() async throws {
        // Given
        let model = try await makeViewModel(authorizationURL: "https://wp.site.example/wp-admin/authorize-application.php",
                                            approvalSiteURL: "https://wp.site.example")

        // When
        let decision = model.decision(for: try #require(URL(string: "https://wp.site.example/wp-admin/authorize-application.php?app_name=woo")))

        // Then
        #expect(decision == .allow)
    }

    @Test(arguments: [
        "https://other.example/wp-admin/authorize-application.php",
        "https://other.example/wp-admin/authorize-application.php/x?app_name=woo",
        "https://other.example/wp-admin%2Fauthorize-application.php?app_name=woo",
        "https://other.example/wp-admin%5Cauthorize-application.php?app_name=woo",
        "https://other.example/x/../wp-admin/authorize-application.php",
        "https://x@site.example/wp-admin/authorize-application.php?app_name=woo",
        "https://site.example.evil.test/wp-admin/authorize-application.php"
    ])
    func test_decision_when_web_view_relays_to_a_foreign_approval_page_then_reports_mismatch_during_approval(url: String) async throws {
        // Given
        let model = try await makeViewModel()

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .siteMismatch(.duringApproval))
    }

    @Test func test_decision_when_listed_page_is_another_site_and_real_store_page_has_a_user_name_then_reports_mismatch() async throws {
        // Given
        let model = try await makeViewModel(authorizationURL: "https://other.example/wp-admin/authorize-application.php",
                                            approvalSiteURL: "https://other.example")
        let url = "https://x@site.example/wp-admin/authorize-application.php?success_url=https://other.example/"

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .siteMismatch(.duringApproval))
    }

    @Test(arguments: [
        "https://network.example/evil/wp-admin/authorize-application.php",
        "https://network.example/shop/../evil/wp-admin/authorize-application.php"
    ])
    func test_decision_when_sibling_multisite_subsite_approval_page_loads_then_reports_mismatch(url: String) async throws {
        // Given
        let model = try await makeViewModel(siteURL: "https://network.example/shop",
                                            authorizationURL: "https://network.example/shop/wp-admin/authorize-application.php")

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .siteMismatch(.duringApproval))
    }

    @Test func test_decision_when_no_authorization_is_fetched_then_any_approval_page_is_a_mismatch() throws {
        // Given
        let model = ApplicationPasswordAuthorizationViewModel(siteURL: "https://site.example", stores: MockStoresManager(sessionManager: .makeForTesting()))

        // When
        let approvalPage = model.decision(for: try #require(URL(string: "https://site.example/wp-admin/authorize-application.php")))
        let loginPage = model.decision(for: try #require(URL(string: "https://site.example/wp-login.php")))

        // Then
        #expect(approvalPage == .siteMismatch(.duringApproval))
        #expect(loginPage == .allow)
    }

    @Test func test_decision_when_foreign_approval_page_would_relabel_site_url_then_cancels_it_before_the_redirect() async throws {
        // Given
        let model = try await makeViewModel()
        let foreignPage = "https://other.example/wp-admin/authorize-application.php?app_name=woo&success_url=woocommerce://application-password"
        let relabeledRedirect = "woocommerce://application-password?user_login=merchant&password=secret&site_url=https://site.example"

        // When
        let pageDecision = model.decision(for: try #require(URL(string: foreignPage)))
        let redirectDecision = model.decision(for: try #require(URL(string: relabeledRedirect)))

        // Then: only the web view check catches it, the redirect alone looks valid.
        #expect(pageDecision == .siteMismatch(.duringApproval))
        #expect(redirectDecision == .approved(username: "merchant", password: "secret"))
    }

    @Test(arguments: [
        "woocommerce://application-password?success=false",
        "woocommerce://application-password?success=false&site_url=https://other.example",
        "woocommerce://application-password?success=false&user_login=merchant&password=secret&site_url=https://site.example"
    ])
    func test_decision_when_redirect_reports_success_false_then_rejects(url: String) async throws {
        // Given
        let model = try await makeViewModel()

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .rejected)
    }

    @Test(arguments: [
        "woocommerce://application-password?user_login=merchant&password=secret&site_url=https://other.example",
        "woocommerce://application-password?user_login=merchant&password=secret&site_url=https://site.example.evil.test",
        "woocommerce://application-password?user_login=merchant&password=secret&site_url=https://wp.site.example",
        "woocommerce://application-password?user_login=merchant&password=secret",
        "woocommerce://application-password?password=secret&site_url=https://other.example",
        "woocommerce://application-password?",
        "woocommerce://application-password"
    ])
    func test_decision_when_redirect_site_url_is_not_the_store_then_reports_mismatch_after_approval(url: String) async throws {
        // Given
        let model = try await makeViewModel()

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .siteMismatch(.afterApproval))
    }

    @Test(arguments: [
        "https://site.example",
        "http://site.example",
        "https://www.site.example",
        "https://site.example/wp",
        "https%3A%2F%2Fsite.example"
    ])
    func test_decision_when_redirect_site_url_is_within_the_store_then_approves(siteURL: String) async throws {
        // Given
        let model = try await makeViewModel()
        let url = "woocommerce://application-password?user_login=merchant&password=secret&site_url=" + siteURL

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .approved(username: "merchant", password: "secret"))
    }

    @Test func test_decision_when_redirect_site_url_is_the_verified_approval_site_then_approves() async throws {
        // Given
        let model = try await makeViewModel(authorizationURL: "https://wp.site.example/wp-admin/authorize-application.php",
                                            approvalSiteURL: "https://wp.site.example")
        let url = "woocommerce://application-password?user_login=merchant&password=secret&site_url=https%3A%2F%2Fwp.site.example"

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .approved(username: "merchant", password: "secret"))
    }

    @Test(arguments: [
        "woocommerce://application-password?password=secret&site_url=https://site.example",
        "woocommerce://application-password?user_login=merchant&site_url=https://site.example",
        "woocommerce://application-password?user_login=&password=secret&site_url=https://site.example",
        "woocommerce://application-password?user_login=merchant&password=&site_url=https://site.example",
        "woocommerce://application-password?user_login&password=secret&site_url=https://site.example"
    ])
    func test_decision_when_redirect_misses_credentials_then_reports_missing_credentials(url: String) async throws {
        // Given
        let model = try await makeViewModel()

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .missingCredentials)
    }

    @Test func test_decision_when_redirect_credentials_are_url_encoded_then_decodes_them() async throws {
        // Given
        let model = try await makeViewModel()
        let url = "woocommerce://application-password?user_login=shop%20manager%40site.example" +
            "&password=abc%2Bdef%26ghi%3D&site_url=https://site.example"

        // When
        let decision = model.decision(for: try #require(URL(string: url)))

        // Then
        #expect(decision == .approved(username: "shop manager@site.example", password: "abc+def&ghi="))
    }

    private func makeViewModel(siteURL: String = "https://site.example",
                               authorizationURL: String = "https://site.example/wp-admin/authorize-application.php",
                               approvalSiteURL: String? = nil) async throws -> ApplicationPasswordAuthorizationViewModel {
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let authorization = ApplicationPasswordAuthorization(url: try #require(URL(string: authorizationURL)), approvalSiteURL: approvalSiteURL)
        stores.whenReceivingAction(ofType: WordPressSiteAction.self) { action in
            if case let .fetchApplicationPasswordAuthorizationURL(_, _, completion) = action {
                completion(.success(authorization))
            }
        }
        let model = ApplicationPasswordAuthorizationViewModel(siteURL: siteURL, stores: stores)
        _ = try await model.fetchAuthURL()
        return model
    }
}

@MainActor
private final class AuthorizationFixture {
    let stores = MockStoresManager(sessionManager: .makeForTesting())
    let provider = MockAnalyticsProvider()
    let form = UIViewController()
    lazy var navigation = AuthorizationNavigationController(rootViewController: form)
    var requestedSites: [String] = []
    var completeFetch: ((Result<ApplicationPasswordAuthorization?, Error>) -> Void)?
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

@MainActor
private final class AuthorizationNavigationController: UINavigationController {
    private(set) var lastPopToViewControllerAnimated: Bool?

    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        lastPopToViewControllerAnimated = animated
        return super.popToViewController(viewController, animated: false)
    }
}
