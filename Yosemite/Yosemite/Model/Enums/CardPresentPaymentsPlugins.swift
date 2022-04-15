import Foundation

public enum CardPresentPaymentsPlugins: Equatable, CaseIterable {
    case wcPay
    case stripe

    public var pluginName: String {
        switch self {
        case .wcPay:
            return "WooCommerce Payments"
        case .stripe:
            return "WooCommerce Stripe Gateway"
        }
    }

    /// Changing values here? You'll need to also update `CardPresentPaymentsOnboardingUseCaseTests`
    ///
    public var minimumSupportedPluginVersion: String {
        switch self {
        case .wcPay:
            return "3.2.1"
        case .stripe:
            return "6.2.0"
        }
    }
}
