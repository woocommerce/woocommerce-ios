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

    init(country: String) throws {
        guard let configuration = Self.countryConfigurations[country] else {
            throw CardPresentPaymentsConfigurationMissingError()
        }
        self = configuration
    }
}

private extension CardPresentPaymentsConfiguration {
    static let countryConfigurations: [String: CardPresentPaymentsConfiguration] = [
        "US": .init(
            paymentMethods: [.cardPresent],
            currencies: ["USD"],
            paymentGateways: [WCPayAccount.gatewayID]
        ),
        "CA": .init(
            paymentMethods: [.cardPresent, .interacPresent],
            currencies: ["CAD"],
            paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID]
        ),
    ]
}

struct CardPresentPaymentsConfigurationMissingError: Error {}
