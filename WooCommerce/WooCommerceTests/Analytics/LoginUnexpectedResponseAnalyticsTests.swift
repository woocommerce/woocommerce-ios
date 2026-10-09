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
