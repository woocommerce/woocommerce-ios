extension WooAnalyticsEvent {
    enum WPComPushNotificationsSetup {
        private enum Keys: String {
            case buttonLabel = "button_label"
        }

        enum BenefitsButton: String {
            case `continue` = "continue"
            case notNow = "not_now"
            case updatePlugin = "update_plugin"
        }

        enum SetupButton: String {
            case done
            case goToMyStore = "go_to_my_store"
            case tryAgain = "try_again"
            case updatePlugin = "update_plugin"
        }

        static func introductionButtonTap(_ button: BenefitsButton) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationsSetupIntroductionButtonTap,
                              properties: [Keys.buttonLabel.rawValue: button.rawValue])
        }

        static func flowButtonTap(_ button: SetupButton) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationsSetupFlowButtonTap,
                              properties: [Keys.buttonLabel.rawValue: button.rawValue])
        }

    }
}

// MARK: - Analytics mapping extensions

extension SetupStep {
    var analyticsKey: String {
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
