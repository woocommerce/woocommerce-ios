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
}

public struct PaymentPluginVersionSupport {
    public let plugin: CardPresentPaymentsPlugins
    public let minimumVersion: String
}
