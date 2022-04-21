import Foundation

public struct CardPresentPaymentsConfiguration {
    private let stripeTerminalforCanadaEnabled: Bool

    public let countryCode: String
    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [CurrencyCode]
    public let paymentGateways: [String]
    public let supportedReaders: [CardReaderType]

    init(countryCode: String,
         stripeTerminalforCanadaEnabled: Bool,
         paymentMethods: [WCPayPaymentMethodType],
         currencies: [CurrencyCode],
         paymentGateways: [String],
         supportedReaders: [CardReaderType]) {
        self.countryCode = countryCode
        self.stripeTerminalforCanadaEnabled = stripeTerminalforCanadaEnabled
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
        self.supportedReaders = supportedReaders
    }

    public init(country: String, canadaEnabled: Bool) {
        switch country {
        case "US":
            self.init(
                countryCode: country,
                stripeTerminalforCanadaEnabled: canadaEnabled,
                paymentMethods: [.cardPresent],
                currencies: [.USD],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2]
            )
        case "CA" where canadaEnabled == true:
            self.init(
                countryCode: country,
                stripeTerminalforCanadaEnabled: true,
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: [.CAD],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3]
            )
        default:
            self.init(
                countryCode: country,
                stripeTerminalforCanadaEnabled: canadaEnabled,
                paymentMethods: [],
                currencies: [],
                paymentGateways: [],
                supportedReaders: []
            )
        }
    }

    public var isSupportedCountry: Bool {
        paymentMethods.isEmpty == false && currencies.isEmpty == false && paymentGateways.isEmpty == false && supportedReaders.isEmpty == false
    }

    /// Given a two character country code, returns a URL where the merchant can purchase a card reader.
    ///
    public func purchaseCardReaderUrl() -> URL {
        URL(string: Constants.purchaseReaderForCountryUrlBase + countryCode) ?? Constants.fallbackInPersonPaymentsUrl
    }
}

private enum Constants {
    static let fallbackInPersonPaymentsUrl = URL(string: "https://woocommerce.com/in-person-payments/")!
    static let purchaseReaderForCountryUrlBase = "https://woocommerce.com/products/hardware/"
}
