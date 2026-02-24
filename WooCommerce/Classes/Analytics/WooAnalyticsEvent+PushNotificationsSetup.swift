extension WooAnalyticsEvent {
    enum PushNotificationsSetup {
        private enum Keys: String {
            case buttonLabel = "button_label"
        }

        enum IntroductionButtonLabel: String {
            case `continue` = "continue"
            case notNow = "not_now"
            case updatePlugin = "update_plugin"
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

        static func flowButtonTap(_ buttonLabel: FlowButtonLabel) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationsSetupFlowButtonTap,
                              properties: [Keys.buttonLabel.rawValue: buttonLabel.rawValue])
        }

    }
}

// MARK: - Analytics mapping extensions

extension SetupStep {
    var analyticsFlowStep: String {
        switch self {
        case .checkPlugin: return "plugin_compatibility"
        case .connect: return "connect_wpcom"
        case .enablePush: return "enable_push_notifications"
        }
    }
}

extension WPComConnectionSetupStep.ErrorType: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .outdatedPlugin(let version):
            return "Outdated plugin version: \(version)"
        case .generic(let reason):
            return reason
        }
    }
}
