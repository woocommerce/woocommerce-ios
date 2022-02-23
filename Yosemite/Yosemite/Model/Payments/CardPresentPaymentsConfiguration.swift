import Foundation

public struct CardPresentPaymentsConfiguration {
    private let countryCode: String

    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [String]
    public let paymentGateways: [String]
    public let supportedReaders: [CardReaderType]

    init(countryCode: String,
         paymentMethods: [WCPayPaymentMethodType],
         currencies: [String],
         paymentGateways: [String],
         supportedReaders: [CardReaderType]) {
        self.countryCode = countryCode
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
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2]
            )
        case "CA" where canadaEnabled == true:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: ["CAD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3]
            )
        default:
            self.init(
                countryCode: country,
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

    /// Given a two character country code and the active plugin, returns a URL
    /// where the merchant can purchase a card reader
    ///
    public func purchaseCardReaderUrl(for plugin: CardPresentPaymentsPlugins) -> URL {
        if case .stripe = plugin {
            return Constants.stripeReaderPurchaseUrl
        }

        return URL(string: Constants.purchaseReaderForCountryUrlBase + self.countryCode) ?? Constants.fallbackInPersonPaymentsUrl
    }
}

private enum Constants {
    static let purchaseM2ReaderUrl = URL(string: "https://woocommerce.com/products/m2-card-reader/")!
    static let fallbackInPersonPaymentsUrl = URL(string: "https://woocommerce.com/in-person-payments/")!
    static let purchaseReaderForCountryUrlBase = "https://woocommerce.com/products/hardware/"
    static let stripeReaderPurchaseUrl = URL(string: "https://stripe.com/terminal/stripe-reader")!
}
