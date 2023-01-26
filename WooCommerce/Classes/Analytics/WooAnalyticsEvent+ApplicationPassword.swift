import enum Networking.ApplicationPasswordUseCaseError

extension WooAnalyticsEvent {
    enum ApplicationPassword {
        private enum Key {
            static let scenario = "scenario"
            static let cause = "cause"
            static let experimentVariant = "experiment_variant"
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

        /// Tracks the REST API A/B test variation
        ///
        static func restAPILoginExperiment(variation: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .trackRestAPILoginExperimentVariation,
                              properties: [Key.experimentVariant: variation])
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
                                                        error: Error) -> WooAnalyticsEvent {
            let failureCause = { () -> FailureCause in
                switch error {
                case ApplicationPasswordUseCaseError.applicationPasswordsDisabled:
                    return .featureDisabled
                case ApplicationPasswordUseCaseError.unauthorizedRequest:
                    return .authorizationFailed
                case ApplicationPasswordUseCaseError.failedToConstructLoginOrAdminURLUsingSiteAddress:
                    return .customLoginOrAdminUrl
                default:
                    return .other
                }
            }()
            return WooAnalyticsEvent(statName: .applicationPasswordsGenerationFailed,
                                     properties: [Key.scenario: scenario.rawValue, Key.cause: failureCause.rawValue],
                                     error: error)
        }
    }
}
