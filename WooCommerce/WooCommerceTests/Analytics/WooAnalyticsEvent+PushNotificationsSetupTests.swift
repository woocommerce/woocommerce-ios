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

    // MARK: - flowSuccess

    @Test func test_flowSuccess_when_given_each_step_then_produces_correct_event() {
        // Given
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.FlowStep, String)] = [
            (.connectWPCom, "connect_wpcom"),
            (.pluginCompatibility, "plugin_compatibility"),
            (.enablePushNotifications, "enable_push_notifications")
        ]

        for (step, expected) in cases {
            // When
            let event = WooAnalyticsEvent.PushNotificationsSetup.flowSuccess(step: step)

            // Then
            #expect(event.statName == .pushNotificationsSetupFlowSuccess)
            #expect(event.properties["step"] as? String == expected)
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
            let event = WooAnalyticsEvent.PushNotificationsSetup.flowButtonTap(buttonLabel: label)

            // Then
            #expect(event.statName == .pushNotificationsSetupFlowButtonTap)
            #expect(event.properties["button_label"] as? String == expected)
        }
    }

    // MARK: - introductionError

    @Test func test_introductionError_when_given_each_error_type_then_produces_correct_event() {
        // Given
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.IntroductionErrorType, String)] = [
            (.noPermission, "no_permission"),
            (.noMissingRequirements, "no_missing_requirements"),
            (.generic, "generic")
        ]

        for (errorType, expected) in cases {
            // When
            let event = WooAnalyticsEvent.PushNotificationsSetup.introductionError(errorType: errorType)

            // Then
            #expect(event.statName == .pushNotificationsSetupIntroductionError)
            #expect(event.properties["error_type"] as? String == expected)
            #expect(event.error == nil)
        }
    }

    @Test func test_introductionError_when_error_provided_then_passes_error_in_event() {
        // Given
        let underlyingError = NSError(domain: "test.domain", code: 99)

        // When
        let event = WooAnalyticsEvent.PushNotificationsSetup.introductionError(errorType: .generic, error: underlyingError)

        // Then
        #expect(event.statName == .pushNotificationsSetupIntroductionError)
        #expect(event.properties["error_type"] as? String == "generic")
        #expect(event.error as? NSError == underlyingError)
    }

    // MARK: - flowError

    @Test func test_flowError_when_no_error_provided_then_produces_correct_event_with_nil_error() {
        // Given
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.FlowStep, String)] = [
            (.connectWPCom, "connect_wpcom"),
            (.pluginCompatibility, "plugin_compatibility"),
            (.enablePushNotifications, "enable_push_notifications")
        ]

        for (step, expected) in cases {
            // When
            let event = WooAnalyticsEvent.PushNotificationsSetup.flowError(step: step)

            // Then
            #expect(event.statName == .pushNotificationsSetupFlowError)
            #expect(event.properties["step"] as? String == expected)
            #expect(event.error == nil)
        }
    }

    @Test func test_flowError_when_error_provided_then_passes_error_in_event() {
        // Given
        let underlyingError = NSError(domain: "test.domain", code: 42)

        // When
        let event = WooAnalyticsEvent.PushNotificationsSetup.flowError(step: .connectWPCom, error: underlyingError)

        // Then
        #expect(event.statName == .pushNotificationsSetupFlowError)
        #expect(event.properties["step"] as? String == "connect_wpcom")
        #expect(event.error as? NSError == underlyingError)
    }
}
