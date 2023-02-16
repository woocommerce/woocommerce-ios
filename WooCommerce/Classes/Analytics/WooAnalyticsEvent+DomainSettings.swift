import enum Yosemite.CreateAccountError

extension WooAnalyticsEvent {
    enum DomainSettings {
        /// Event property keys.
        private enum Key {
            static let source = "source"
            static let hasDomainCredit = "has_domain_credit"
            static let useDomainCredit = "use_domain_credit"
        }

        /// Tracked when the user taps to search for domains from the domain dashboard screen.
        static func domainSettingsAddDomainTapped(source: DomainSettingsCoordinator.Source, hasDomainCredit: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .domainSettingsAddDomainTapped,
                              properties: [Key.source: source.analyticsValue,
                                           Key.hasDomainCredit: hasDomainCredit])
        }

        /// Tracked when the user selects a domain from the domain selector to purchase or redeem.
        static func domainSettingsCustomDomainSelected(source: DomainSettingsCoordinator.Source, useDomainCredit: Bool) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .domainSettingsCustomDomainSelected,
                              properties: [Key.source: source.analyticsValue,
                                           Key.useDomainCredit: useDomainCredit])
        }

        /// Tracked when the domain contact info validation succeeds when redeeming a domain with domain credit.
        static func domainContactInfoValidationSuccess(source: DomainSettingsCoordinator.Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .domainContactInfoValidationSuccess, properties: [Key.source: source.analyticsValue])
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

private extension DomainSettingsCoordinator.Source {
    var analyticsValue: String {
        switch self {
        case .settings:
            return "settings"
        }
    }
}
