import Foundation

public enum CardPresentPaymentsPlugin: Equatable, CaseIterable {
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
    public let plugin: CardPresentPaymentsPlugin
    public let minimumVersion: String
}
