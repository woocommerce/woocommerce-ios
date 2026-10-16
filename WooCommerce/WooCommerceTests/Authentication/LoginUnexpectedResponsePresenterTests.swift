import UIKit
import Testing
@testable import WooCommerce

@MainActor
struct LoginUnexpectedResponsePresenterTests {
    @Test func test_alert_when_presented_then_has_standard_copy_and_tracks_once_after_completion() {
        // Given
        let fixture = Fixture()

        // When
        fixture.show()

        // Then
        #expect(fixture.alert?.title == "Unable to log in")
        #expect(fixture.alert?.message ==
                "Your store returned an unexpected response, so we couldn’t finish logging you in. Try again or contact support for help.")
        #expect(fixture.alert?.actions.map(\.title) == ["Try Again", "Contact Support", "Dismiss"])
        #expect(fixture.provider.receivedEvents.isEmpty)
        fixture.presentationCompletion?()
        fixture.presentationCompletion?()
        #expect(fixture.provider.receivedEvents == [WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue])
    }

    @Test(arguments: [true, false])
    func test_retry_when_completed_then_tracks_original_context_and_one_result(success: Bool) {
        // Given
        let fixture = Fixture()
        fixture.show()
        fixture.presentationCompletion?()

        // When
        fixture.presenter.select(.retry)
        fixture.presenter.select(.retry)
        fixture.retryCompletion?(success)
        fixture.retryCompletion?(!success)

        // Then
        #expect(fixture.retryCount == 1)
        #expect(fixture.provider.receivedEvents == [
            WooAnalyticsStat.loginUnexpectedResponseErrorShown.rawValue,
            WooAnalyticsStat.loginUnexpectedResponseActionTapped.rawValue,
            WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue
        ])
        #expect(fixture.provider.receivedProperties.last as? [String: String] == [
            "step": "login_page", "login_flow": "site_credentials", "failure_kind": "unexpected_content",
            "result": success ? "success" : "failure"
        ])
    }

    @Test func test_repeated_failure_when_retry_finishes_then_allows_a_new_alert() {
        // Given
        let fixture = Fixture()
        fixture.show()
        fixture.presenter.select(.retry)

        // When
        fixture.show()
        #expect(fixture.presentationCount == 1)
        fixture.retryCompletion?(false)
        fixture.show()

        // Then
        #expect(fixture.presentationCount == 2)
    }

    @Test(arguments: [LoginUnexpectedResponseFailure.Action.contactSupport, .dismiss])
    func test_nonretry_action_when_selected_then_prepares_selected_action_and_does_not_track_retry(action: LoginUnexpectedResponseFailure.Action) {
        // Given
        let fixture = Fixture()
        fixture.show()

        // When
        fixture.presenter.select(action)
        fixture.presenter.select(action)

        // Then
        #expect(fixture.dismissCount == (action == .dismiss ? 1 : 0))
        #expect(fixture.supportPreparationCount == (action == .contactSupport ? 1 : 0))
        #expect(fixture.supportCount == (action == .contactSupport ? 1 : 0))
        #expect(fixture.retryCount == 0)
        if action == .contactSupport {
            #expect(fixture.supportContext?.siteURL == "https://example.com")
            #expect(fixture.supportContext?.failure.step == .loginPage)
            #expect(fixture.supportContext?.flow == .siteCredentials)
        }
        #expect(fixture.provider.receivedEvents == [WooAnalyticsStat.loginUnexpectedResponseActionTapped.rawValue])
        #expect(fixture.provider.receivedProperties.last?["action"] as? String == action.rawValue)
    }

    @Test func test_cancellation_when_retry_is_running_then_ignores_stale_completion_and_allows_new_alert() {
        // Given
        let fixture = Fixture()
        fixture.show()
        fixture.presenter.select(.retry)
        let staleResult = fixture.retryCompletion

        // When
        fixture.presenter.invalidate()
        fixture.show()
        staleResult?(true)

        // Then
        #expect(fixture.presentationCount == 2)
        #expect(!fixture.provider.receivedEvents.contains(WooAnalyticsStat.loginUnexpectedResponseRetryResult.rawValue))
    }

    @Test func test_cancellation_when_presentation_is_pending_then_does_not_track_shown_or_actions() {
        // Given
        let fixture = Fixture()
        fixture.show()

        // When
        fixture.presenter.invalidate()
        fixture.presentationCompletion?()
        fixture.presenter.select(.dismiss)

        // Then
        #expect(fixture.provider.receivedEvents.isEmpty)
    }

    @Test func test_support_when_selected_then_opens_ai_chat_directly() {
        // Given
        let source = UIViewController()
        let navigation = UINavigationController(rootViewController: source)
        let presenter = LoginUnexpectedResponsePresenter(presentation: { _, _, completion in completion() })
        presenter.present(failure: .init(stage: .preflight), flow: .siteCredentials, from: source, onRetry: { _ in })

        // When
        presenter.select(.contactSupport)

        // Then
        #expect(navigation.topViewController is SupportChatHostingController)
        #expect(navigation.viewControllers.count == 2)
    }
}

@MainActor
private final class Fixture {
    let provider = MockAnalyticsProvider()
    let controller = UIViewController()
    var alert: UIAlertController?
    var presentationCompletion: (() -> Void)?
    var retryCompletion: ((Bool) -> Void)?
    var presentationCount = 0
    var retryCount = 0
    var dismissCount = 0
    var supportPreparationCount = 0
    var supportCount = 0
    var supportContext: LoginSupportContext?
    lazy var presenter = LoginUnexpectedResponsePresenter(
        analytics: WooAnalytics(analyticsProvider: provider),
        presentation: { [weak self] _, alert, completion in
            self?.presentationCount += 1
            self?.alert = alert
            self?.presentationCompletion = completion
        },
        support: { [weak self] _, context in
            self?.supportCount += 1
            self?.supportContext = context
        }
    )

    func show() {
        presenter.present(failure: .init(stage: .preflight), flow: .siteCredentials, from: controller, siteURL: "https://example.com",
                          onRetry: { [weak self] result in
            self?.retryCount += 1
            self?.retryCompletion = result
        }, onDismiss: { [weak self] in self?.dismissCount += 1 },
                          onContactSupport: { [weak self] in self?.supportPreparationCount += 1 })
    }
}
