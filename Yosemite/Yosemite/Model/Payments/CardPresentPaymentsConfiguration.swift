import Foundation

public struct CardPresentPaymentsConfiguration {
    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [String]
    public let paymentGateways: [String]
    public let supportedCardReaders: [CardReaderType]

    init(paymentMethods: [WCPayPaymentMethodType], currencies: [String], paymentGateways: [String], supportedCardReaders: [CardReaderType]) {
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
        self.supportedCardReaders = supportedCardReaders
    }

    public init(country: String, stripeEnabled: Bool, canadaEnabled: Bool) throws {
        switch country {
        case "US" where stripeEnabled == true:
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedCardReaders: [.chipper, .stripeM2]
            )
        case "US" where stripeEnabled == false:
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedCardReaders: [.chipper, .stripeM2]
            )
        case "CA" where canadaEnabled == true:
            self.init(
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: ["CAD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedCardReaders: [.wisepad3]
            )
        default:
            throw CardPresentPaymentsConfigurationMissingError()
        }
    }

    var supportsStripe: Bool {
        paymentGateways.contains(StripeAccount.gatewayID)
    }
}

public struct CardPresentPaymentsConfigurationMissingError: Error {}
