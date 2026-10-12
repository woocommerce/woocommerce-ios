import Testing
import NetworkingCore
@testable import WooCommerce

struct LoginUnexpectedResponseAnalyticsTests {
    @Test func test_error_shown_when_originating_flow_changes_then_uses_the_supplied_flow() {
        for (flow, value) in [(LoginUnexpectedResponseFailure.LoginFlow.siteCredentials, "site_credentials"),
                              (.appPassword, "app_password"), (.storePicker, "store_picker")] {
            // Given
            let failure = LoginUnexpectedResponseFailure(stage: .preflight)

            // When
            let event = WooAnalyticsEvent.Login.unexpectedResponseShown(failure: failure, loginFlow: flow)

            // Then
            #expect(event.properties["login_flow"] as? String == value)
        }
    }

    @Test func test_action_and_retry_events_when_created_then_include_only_original_context_and_outcome() {
        for flow in [LoginUnexpectedResponseFailure.LoginFlow.siteCredentials, .appPassword, .storePicker] {
            for code: Int? in [nil, 500] {
                // Given
                let failure = LoginUnexpectedResponseFailure(stage: .dashboard, statusCode: code)
                let context = ["step": "dashboard_verification", "login_flow": flow.rawValue,
                               "failure_kind": code == nil ? "unexpected_content" : "unacceptable_status_code"]

                // When / Then
                for action in [LoginUnexpectedResponseFailure.Action.retry, .contactSupport, .dismiss] {
                    let event = WooAnalyticsEvent.Login.unexpectedResponseActionTapped(failure: failure, loginFlow: flow, action: action)
                    #expect(event.statName.rawValue == "login_unexpected_response_action_tapped")
                    #expect(event.properties as? [String: String] == context.merging(["action": action.rawValue]) { _, new in new })
                    #expect(event.error == nil)
                }
                for success in [true, false] {
                    let event = WooAnalyticsEvent.Login.unexpectedResponseRetryResult(failure: failure, loginFlow: flow, success: success)
                    #expect(event.statName.rawValue == "login_unexpected_response_retry_result")
                    #expect(event.properties as? [String: String] == context.merging(["result": success ? "success" : "failure"]) { _, new in new })
                    #expect(event.error == nil)
                }
            }
        }
    }

    @Test func test_error_shown_when_credential_response_fails_then_contains_only_agreed_properties() {
        let stages: [(CookieNonceAuthenticationResponseStage, String)] = [
            (.preflight, "login_page"), (.credentials, "credentials_submission"),
            (.dashboard, "dashboard_verification"), (.nonce, "nonce_retrieval")
        ]
        for (stage, step) in stages {
            for code: Int? in [nil, 500] {
                // Given
                let failure = LoginUnexpectedResponseFailure(stage: stage, statusCode: code)

                // When
                let event = WooAnalyticsEvent.Login.unexpectedResponseShown(failure: failure, loginFlow: .siteCredentials)

                // Then
                #expect(event.statName.rawValue == "login_unexpected_response_error_shown")
                #expect(event.properties as? [String: String] == [
                    "login_flow": "site_credentials",
                    "failure_kind": code == nil ? "unexpected_content" : "unacceptable_status_code",
                    "step": step
                ])
                #expect(event.error == nil)
            }
        }
    }
}
