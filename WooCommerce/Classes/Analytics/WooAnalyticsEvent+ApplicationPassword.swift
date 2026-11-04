import enum Networking.ApplicationPasswordUseCaseError
import protocol WooFoundation.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {
    enum ApplicationPassword {
        private enum Key {
            static let scenario = "scenario"
            static let cause = "cause"
            static let path = "path"
            static let isAppInForeground = "is_app_in_foreground"
        }

        enum Scenario: String {
            case generation = "generation"
            case regeneration = "regeneration"
        }

        private enum FailureCause: String {
            case authorizationFailed = "authorization_failed"
            case featureDisabled = "feature_disabled"
            case customLoginOrAdminUrl = "custom_login_or_admin_url"
            case other = "other"
        }

        /// Tracks when generating application password succeeds
        ///
        static func applicationPasswordGeneratedSuccessfully(scenario: Scenario) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .applicationPasswordsNewPasswordCreated,
                              properties: [Key.scenario: scenario.rawValue])
        }

        /// Tracks when generating application password fails
        ///
        static func applicationPasswordGenerationFailed(scenario: Scenario,
                                                        error: Error,
                                                        path: String? = nil,
                                                        isAppInForeground: Bool? = nil) -> WooAnalyticsEvent {
            let failureCause = { () -> FailureCause in
                switch error {
                case ApplicationPasswordUseCaseError.applicationPasswordsDisabled:
                    return .featureDisabled
                case ApplicationPasswordUseCaseError.unauthorizedRequest, ApplicationPasswordUseCaseError.siteCredentialsRejected:
                    return .authorizationFailed
                case ApplicationPasswordUseCaseError.failedToConstructLoginOrAdminURLUsingSiteAddress:
                    return .customLoginOrAdminUrl
                default:
                    return .other
                }
            }()
            let properties: [String: WooAnalyticsEventPropertyType?] = [
                Key.scenario: scenario.rawValue,
                Key.cause: failureCause.rawValue,
                Key.path: path,
                Key.isAppInForeground: isAppInForeground
            ]
            return WooAnalyticsEvent(statName: .applicationPasswordsGenerationFailed,
                                     properties: properties.compactMapValues { $0 },
                                     error: error)
        }
    }
}
