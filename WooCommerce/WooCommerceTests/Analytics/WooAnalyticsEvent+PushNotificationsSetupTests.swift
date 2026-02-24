import Foundation
import Testing
@testable import WooCommerce

struct WooAnalyticsEvent_PushNotificationsSetupTests {

    // MARK: - introductionButtonTap

    @Test func test_introductionButtonTap_when_given_each_label_then_produces_correct_event() {
        // Given
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.IntroductionButtonLabel, String)] = [
            (.continue, "continue"),
            (.notNow, "not_now"),
            (.updatePlugin, "update_plugin")
        ]

        for (label, expected) in cases {
            // When
            let event = WooAnalyticsEvent.PushNotificationsSetup.introductionButtonTap(buttonLabel: label)

            // Then
            #expect(event.statName == .pushNotificationsSetupIntroductionButtonTap)
            #expect(event.properties["button_label"] as? String == expected)
        }
    }

    // MARK: - flowButtonTap

    @Test func test_flowButtonTap_when_given_each_label_then_produces_correct_event() {
        // Given
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.FlowButtonLabel, String)] = [
            (.done, "done"),
            (.goToMyStore, "go_to_my_store"),
            (.tryAgain, "try_again"),
            (.updatePlugin, "update_plugin")
        ]

        for (label, expected) in cases {
            // When
            let event = WooAnalyticsEvent.PushNotificationsSetup.flowButtonTap(label)

            // Then
            #expect(event.statName == .pushNotificationsSetupFlowButtonTap)
            #expect(event.properties["button_label"] as? String == expected)
        }
    }
}
