import Foundation

/// Contains the state related to active plugins when Card-Present Payments onboarding is complete
///
public struct CardPresentPaymentsPluginState: Equatable {
    /// The plugin to use for Card-Present Payments
    ///
    public let preferred: CardPresentPaymentsPlugin

    /// The list of plugins available for Card-Present Payments
    ///
    /// When this list contains more than one plugin, the user will be able to select their preferred payment gateway
    ///
    public let available: [CardPresentPaymentsPlugin]

    /// Initializes the state with the preferred plugin and the list of all available plugins
    ///
    /// - Important: The available parameter must also contain the preferred plugin
    ///
    public init(preferred: CardPresentPaymentsPlugin, available: [CardPresentPaymentsPlugin]) {
        precondition(available.contains(preferred))
        self.preferred = preferred
        self.available = available
    }

    /// Convenience initializer to use when a single plugin is available
    ///
    public init(plugin: CardPresentPaymentsPlugin) {
        self.preferred = plugin
        self.available = [plugin]
    }
}

// MARK: - Shorthand helpers for testing/previes
public extension CardPresentPaymentsPluginState {
    /// Returns a state where only WCPay is available
    ///
    static var wcPayOnly: Self {
        .init(plugin: .wcPay)
    }

    /// Returns a state where only Stripe is available
    ///
    static var stripeOnly: Self {
        .init(plugin: .stripe)
    }

    /// Returns a state where both plugins are available but WCPay is the preferred one
    ///
    static var wcPayPreferred: Self {
        .init(preferred: .wcPay, available: [.wcPay, .stripe])
    }

    /// Returns a state where both plugins are available but Stripe is the preferred one
    ///
    static var stripePreferred: Self {
        .init(preferred: .stripe, available: [.wcPay, .stripe])
    }
}
