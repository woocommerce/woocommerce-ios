import Foundation
import Testing
@testable import WooCommerce

struct WooAnalyticsEvent_PushNotificationsSetupTests {

    // MARK: - introductionView

    @Test func test_introductionView_when_given_each_state_then_produces_correct_event() {
        // Given
        let cases: [(WooAnalyticsEvent.WPComPushNotificationsSetup.IntroductionViewState, String)] = [
            (.notConnected, "not_connected"),
            (.updateRequired, "update_required"),
            (.connected, "connected")
        ]

        for (state, expected) in cases {
            // When
            let event = WooAnalyticsEvent.WPComPushNotificationsSetup.introductionView(state: state)

            // Then
            #expect(event.statName == .pushNotificationsSetupIntroductionView)
            #expect(event.properties["state"] as? String == expected)
        }
    }

    // MARK: - introductionButtonTap

    @Test func test_introductionButtonTap_when_given_each_label_then_produces_correct_event() {
        // Given
        let cases: [(WooAnalyticsEvent.WPComPushNotificationsSetup.BenefitsButton, String)] = [
            (.continue, "continue"),
            (.notNow, "not_now"),
            (.updatePlugin, "update_plugin")
        ]

        for (button, expected) in cases {
            // When
            let event = WooAnalyticsEvent.WPComPushNotificationsSetup.introductionButtonTap(button)

            // Then
            #expect(event.statName == .pushNotificationsSetupIntroductionButtonTap)
            #expect(event.properties["button_label"] as? String == expected)
        }
    }

    // MARK: - flowButtonTap

    @Test func test_flowButtonTap_when_given_each_label_then_produces_correct_event() {
        // Given
        let cases: [(WooAnalyticsEvent.WPComPushNotificationsSetup.SetupButton, String)] = [
            (.goToMyStore, "go_to_my_store"),
            (.tryAgain, "try_again"),
            (.updatePlugin, "update_plugin")
        ]

        for (button, expected) in cases {
            // When
            let event = WooAnalyticsEvent.WPComPushNotificationsSetup.flowButtonTap(button)

            // Then
            #expect(event.statName == .pushNotificationsSetupFlowButtonTap)
            #expect(event.properties["button_label"] as? String == expected)
        }
    }
}
