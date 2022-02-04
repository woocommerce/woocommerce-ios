import Foundation

struct CardPresentPaymentsConfiguration {
    let paymentMethods: [WCPayPaymentMethodType]
    let currencies: [String]
    let paymentGateways: [String]

    init(paymentMethods: [WCPayPaymentMethodType], currencies: [String], paymentGateways: [String]) {
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
    }

    init(country: String, stripeEnabled: Bool, canadaEnabled: Bool) throws {
        switch country {
        case "US" where stripeEnabled == true:
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID]
            )
        case "US" where stripeEnabled == false:
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID]
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

struct CardPresentPaymentsConfigurationMissingError: Error {}
