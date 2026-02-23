import Foundation

extension WooAnalyticsEvent {
    enum PushNotificationsSetup {
        private enum Keys: String {
            case buttonLabel = "button_label"
            case step
        }

        enum IntroductionButtonLabel: String {
            case `continue` = "continue"
            case notNow = "not_now"
            case updatePlugin = "update_plugin"
        }

        enum FlowStep: String {
            case connectWPCom = "connect_wpcom"
            case pluginCompatibility = "plugin_compatibility"
            case enablePushNotifications = "enable_push_notifications"
        }

        enum FlowButtonLabel: String {
            case done
            case goToMyStore = "go_to_my_store"
            case tryAgain = "try_again"
            case updatePlugin = "update_plugin"
        }

        static func introductionButtonTap(buttonLabel: IntroductionButtonLabel) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationsSetupIntroductionButtonTap,
                              properties: [Keys.buttonLabel.rawValue: buttonLabel.rawValue])
        }

        static func flowSuccess(step: FlowStep) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationsSetupFlowSuccess,
                              properties: [Keys.step.rawValue: step.rawValue])
        }

        static func flowButtonTap(buttonLabel: FlowButtonLabel) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationsSetupFlowButtonTap,
                              properties: [Keys.buttonLabel.rawValue: buttonLabel.rawValue])
        }

        static func flowError(step: FlowStep, error: Error? = nil) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationsSetupFlowError,
                              properties: [Keys.step.rawValue: step.rawValue],
                              error: error)
        }
    }
}
