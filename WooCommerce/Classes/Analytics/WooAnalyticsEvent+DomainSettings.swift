import enum Yosemite.CreateAccountError

extension WooAnalyticsEvent {
    enum DomainSettings {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let step = "step"
            static let useDomainCredit = "use_domain_credit"
        }

        /// Tracked step for each step in the custom domains.
        static func domainSettingsStep(source: DomainSettingsCoordinator.Source, step: Step) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .domainSettingsStep, properties: [
                Key.source: source.analyticsValue,
                Key.step: step.rawValue
            ])
        }

        /// Tracked when the domain contact info validation fails when redeeming a domain with domain credit.
        static func domainContactInfoValidationFailed(source: DomainSettingsCoordinator.Source, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .domainContactInfoValidationFailed,
                              properties: [Key.source: source.analyticsValue],
                              error: error)
        }

        /// Tracked when the custom domain purchase or redemption succeeds.
        static func domainSettingsCustomDomainPurchaseSuccess(source: DomainSettingsCoordinator.Source, useDomainCredit: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .domainSettingsCustomDomainPurchaseSuccess,
                              properties: [Key.source: source.analyticsValue, Key.useDomainCredit: useDomainCredit])
        }

        /// Tracked when the custom domain purchase or redemption fails.
        static func domainSettingsCustomDomainPurchaseFailed(source: DomainSettingsCoordinator.Source,
                                                             useDomainCredit: Bool,
                                                             error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .domainSettingsCustomDomainPurchaseFailed,
                              properties: [Key.source: source.analyticsValue, Key.useDomainCredit: useDomainCredit],
                              error: error)
        }
    }
}

extension WooAnalyticsEvent.DomainSettings {
    /// Steps of the domain settings flow. The raw value is used for the event property.
    enum Step: String {
        case dashboard = "dashboard"
        case domainSelector = "picker"
        case webCheckout = "web_checkout"
        case contactInfo = "contact_info"
        case purchaseSuccess = "purchase_success"
    }
}

private extension DomainSettingsCoordinator.Source {
    var analyticsValue: String {
        switch self {
        case .settings:
            return "settings"
        }
    }
}
