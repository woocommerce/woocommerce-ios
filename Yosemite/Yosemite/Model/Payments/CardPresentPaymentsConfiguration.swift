import Foundation

public struct CardPresentPaymentsConfiguration {
    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [String]
    public let paymentGateways: [String]
    public let supportedReaders: [CardReaderType]

    init(paymentMethods: [WCPayPaymentMethodType], currencies: [String], paymentGateways: [String], supportedReaders: [CardReaderType]) {
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
        self.supportedReaders = supportedReaders
    }

    public init(country: String, stripeEnabled: Bool, canadaEnabled: Bool) {
        switch country {
        case "US" where stripeEnabled == true:
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2]
            )
        case "US" where stripeEnabled == false:
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2]
            )
        case "CA" where canadaEnabled == true:
            self.init(
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: ["CAD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3]
            )
        default:
            self.init(paymentMethods: [], currencies: [], paymentGateways: [], supportedReaders: [])
        }
    }

    public var isSupportedCountry: Bool {
        paymentMethods.isEmpty == false && currencies.isEmpty == false && paymentGateways.isEmpty == false
    }
}
