import Foundation

extension WooAnalyticsEvent {
    enum JetpackSetup {
        private enum Key: String {
            case isAlreadyConnected = "is_already_connected"
            case requiresConnectionOnly = "requires_connection_only"
            case tap
            case step
        }

        enum LoginFlow {
            enum TapTarget: String {
                case submit
                case dismiss
            }

            enum Step: String {
                case emailAddress = "email_address"
                case password
                case magicLink = "magic_link"
                case verificationCode = "verification_code"
            }
        }

        enum SetupFlow {
            enum TapTarget: String {
                case dismiss
                case support
                case continueSetup = "continue_setup"
                case goToStore = "go_to_store"
                case retry
            }
        }

        static func connectionCheckCompleted(isAlreadyConnected: Bool, requiresConnectionOnly: Bool) -> WooAnalyticsEvent {
            .init(statName: .jetpackSetupConnectionCheckCompleted, properties: [
                Key.isAlreadyConnected.rawValue: isAlreadyConnected,
                Key.requiresConnectionOnly.rawValue: requiresConnectionOnly
            ])
        }

        static func loginFlow(step: LoginFlow.Step, tap: LoginFlow.TapTarget? = nil, failure: Error? = nil) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [Key.step.rawValue: step.rawValue]
            if let tap {
                properties[Key.tap.rawValue] = tap.rawValue
            }
            return .init(statName: .jetpackSetupLoginFlow, properties: properties, error: failure)
        }

        static func setupFlow(step: JetpackInstallStep, tap: SetupFlow.TapTarget? = nil, failure: Error? = nil) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [Key.step.rawValue: step.analyticsValue]
            if let tap {
                properties[Key.tap.rawValue] = tap.rawValue
            }
            return .init(statName: .jetpackSetupFlow, properties: properties, error: failure)
        }
    }
}
