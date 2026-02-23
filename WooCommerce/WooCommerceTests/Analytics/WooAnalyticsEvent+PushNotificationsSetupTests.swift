import XCTest
@testable import WooCommerce

final class WooAnalyticsEvent_PushNotificationsSetupTests: XCTestCase {

    // MARK: - introductionButtonTap

    func test_introductionButtonTap_produces_correct_events() {
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.IntroductionButtonLabel, String)] = [
            (.continue, "continue"),
            (.notNow, "not_now"),
            (.updatePlugin, "update_plugin")
        ]
        for (label, expected) in cases {
            let event = WooAnalyticsEvent.PushNotificationsSetup.introductionButtonTap(buttonLabel: label)
            XCTAssertEqual(event.statName, .pushNotificationsSetupIntroductionButtonTap)
            XCTAssertEqual(event.properties["button_label"] as? String, expected)
        }
    }

    // MARK: - flowSuccess

    func test_flowSuccess_produces_correct_events() {
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.FlowStep, String)] = [
            (.connectWPCom, "connect_wpcom"),
            (.pluginCompatibility, "plugin_compatibility"),
            (.enablePushNotifications, "enable_push_notifications")
        ]
        for (step, expected) in cases {
            let event = WooAnalyticsEvent.PushNotificationsSetup.flowSuccess(step: step)
            XCTAssertEqual(event.statName, .pushNotificationsSetupFlowSuccess)
            XCTAssertEqual(event.properties["step"] as? String, expected)
        }
    }

    // MARK: - flowButtonTap

    func test_flowButtonTap_produces_correct_events() {
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.FlowButtonLabel, String)] = [
            (.done, "done"),
            (.goToMyStore, "go_to_my_store"),
            (.tryAgain, "try_again"),
            (.updatePlugin, "update_plugin")
        ]
        for (label, expected) in cases {
            let event = WooAnalyticsEvent.PushNotificationsSetup.flowButtonTap(buttonLabel: label)
            XCTAssertEqual(event.statName, .pushNotificationsSetupFlowButtonTap)
            XCTAssertEqual(event.properties["button_label"] as? String, expected)
        }
    }

    // MARK: - flowError

    func test_flowError_without_error_produces_correct_events() {
        let cases: [(WooAnalyticsEvent.PushNotificationsSetup.FlowStep, String)] = [
            (.connectWPCom, "connect_wpcom"),
            (.pluginCompatibility, "plugin_compatibility"),
            (.enablePushNotifications, "enable_push_notifications")
        ]
        for (step, expected) in cases {
            let event = WooAnalyticsEvent.PushNotificationsSetup.flowError(step: step)
            XCTAssertEqual(event.statName, .pushNotificationsSetupFlowError)
            XCTAssertEqual(event.properties["step"] as? String, expected)
            XCTAssertNil(event.error)
        }
    }

    func test_flowError_with_error_passes_error_in_event() {
        // Given
        let underlyingError = NSError(domain: "test.domain", code: 42)

        // When
        let event = WooAnalyticsEvent.PushNotificationsSetup.flowError(step: .connectWPCom, error: underlyingError)

        // Then
        XCTAssertEqual(event.statName, .pushNotificationsSetupFlowError)
        XCTAssertEqual(event.properties["step"] as? String, "connect_wpcom")
        XCTAssertEqual(event.error as? NSError, underlyingError)
    }
}
