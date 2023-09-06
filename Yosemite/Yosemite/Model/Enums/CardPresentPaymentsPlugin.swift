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

    public var fileNameWithoutExtension: String {
        switch self {
        case .wcPay:
            return "woocommerce-payments"
        case .stripe:
            return "woocommerce-gateway-stripe"
        }
    }

    public var fileNameWithPathExtension: String {
        switch self {
        case .wcPay:
            return "woocommerce-payments/woocommerce-payments"
        case .stripe:
            return "woocommerce-gateway-stripe/woocommerce-gateway-stripe"
        }
    }

    public var gatewayID: String {
        switch self {
        case .wcPay:
            return WCPayAccount.gatewayID
        case .stripe:
            return StripeAccount.gatewayID
        }
    }

    public static func with(gatewayID: String) -> Self? {
        allCases.first(where: { $0.gatewayID == gatewayID })
    }
}

public struct PaymentPluginVersionSupport: Equatable {
    public let plugin: CardPresentPaymentsPlugin
    public let minimumVersion: String
}
