import enum Yosemite.CardPresentPaymentOnboardingState

extension CardPresentPaymentOnboardingState {
    /// Payment gateway ID for analytics.
    public var gatewayID: String? {
        switch self {
            case let .completed(pluginState):
                return pluginState.preferred.gatewayID
            case let .pluginUnsupportedVersion(plugin: plugin),
                let .pluginNotActivated(plugin),
                let .pluginSetupNotCompleted(plugin),
                let .pluginInTestModeWithLiveStripeAccount(plugin),
                let .stripeAccountUnderReview(plugin),
                let .stripeAccountOverdueRequirement(plugin),
                let .stripeAccountRejected(plugin),
                let .codPaymentGatewayNotSetUp(plugin),
                let .stripeAccountPendingRequirement(plugin, _),
                let .countryNotSupportedStripe(plugin, _):
                return plugin.gatewayID
            case .loading, .selectPlugin, .countryNotSupported, .pluginNotInstalled, .genericError, .noConnectionError:
                return nil
        }
    }
}
