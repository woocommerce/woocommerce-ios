import Foundation

public enum CardPresentPaymentsPlugin: Equatable, CaseIterable {
    case wcPay
    case stripe
    case paypal

    public var pluginName: String {
        switch self {
        case .wcPay:
            return "WooPayments"
        case .stripe:
            return "WooCommerce Stripe Gateway"
        case .paypal:
            return "WooCommerce PayPal Payments"
        }
    }

    public var plugin: Plugin {
        switch self {
        case .wcPay:
            return .wooPayments
        case .stripe:
            return .stripe
        case .paypal:
            return .wooPayPal
        }
    }

    public var fileNameWithPathExtension: String {
        switch self {
        case .wcPay:
            return "woocommerce-payments/woocommerce-payments"
        case .stripe:
            return "woocommerce-gateway-stripe/woocommerce-gateway-stripe"
        case .paypal:
            return "woocommerce-paypal-payments/woocommerce-paypal-payments"
        }
    }

    public var gatewayID: String {
        switch self {
        case .wcPay:
            return WCPayAccount.gatewayID
        case .stripe:
            return StripeAccount.gatewayID
        case .paypal:
            return "paypal"
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
