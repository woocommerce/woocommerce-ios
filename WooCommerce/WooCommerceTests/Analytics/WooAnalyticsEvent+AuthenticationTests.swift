import Foundation
import Testing
@testable import WooCommerce

struct WooAnalyticsEvent_AuthenticationTests {

    // MARK: - involuntaryLogout

    @Test func test_involuntaryLogout_when_given_each_reason_then_produces_correct_event() {
        // Given
        let cases: [(WooAnalyticsEvent.Authentication.InvoluntaryLogoutReason, String)] = [
            (.invalidToken, "invalid_token"),
            (.applicationPasswordUnauthorized, "application_password_unauthorized"),
            (.appleIDCredentialRevoked, "apple_id_credential_revoked")
        ]

        for (reason, expected) in cases {
            // When
            let event = WooAnalyticsEvent.Authentication.involuntaryLogout(reason: reason)

            // Then
            #expect(event.statName == .involuntaryLogout)
            #expect(event.properties["reason"] as? String == expected)
        }
    }
}
