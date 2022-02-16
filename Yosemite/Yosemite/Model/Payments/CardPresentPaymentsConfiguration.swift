import Foundation

public struct CardPresentPaymentsConfiguration {
    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [String]
    public let paymentGateways: [String]

    init(paymentMethods: [WCPayPaymentMethodType], currencies: [String], paymentGateways: [String]) {
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
    }

    public init(country: String, canadaEnabled: Bool) throws {
        switch country {
        case "US":
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID]
            )
        case "CA" where canadaEnabled == true:
            self.init(
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: ["CAD"],
                paymentGateways: [WCPayAccount.gatewayID]
            )
        default:
            throw CardPresentPaymentsConfigurationMissingError()
        }
    }
}

public struct CardPresentPaymentsConfigurationMissingError: Error {}
