import Foundation

public struct CardPresentPaymentsConfiguration {
    private let stripeTerminalforCanadaEnabled: Bool

    public let countryCode: String
    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [CurrencyCode]
    public let paymentGateways: [String]
    public let supportedReaders: [CardReaderType]
    public let supportedPluginVersions: [PaymentPluginVersionSupport]

    init(countryCode: String,
         stripeTerminalforCanadaEnabled: Bool,
         paymentMethods: [WCPayPaymentMethodType],
         currencies: [CurrencyCode],
         paymentGateways: [String],
         supportedReaders: [CardReaderType],
         supportedPluginVersions: [PaymentPluginVersionSupport]) {
        self.countryCode = countryCode
        self.stripeTerminalforCanadaEnabled = stripeTerminalforCanadaEnabled
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
        self.supportedReaders = supportedReaders
        self.supportedPluginVersions = supportedPluginVersions
    }

    public init(country: String, canadaEnabled: Bool) {
        /// Changing `minimumVersion` values here? You'll need to also update `CardPresentPaymentsOnboardingUseCaseTests`
        switch country {
        case "US":
            self.init(
                countryCode: country,
                stripeTerminalforCanadaEnabled: canadaEnabled,
                paymentMethods: [.cardPresent],
                currencies: [.USD],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: "3.2.1"),
                    .init(plugin: .stripe, minimumVersion: "6.2.0")
                ]
            )
        case "CA" where canadaEnabled == true:
            self.init(
                countryCode: country,
                stripeTerminalforCanadaEnabled: true,
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: [.CAD],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.0.0")]
            )
        default:
            self.init(
                countryCode: country,
                stripeTerminalforCanadaEnabled: canadaEnabled,
                paymentMethods: [],
                currencies: [],
                paymentGateways: [],
                supportedReaders: [],
                supportedPluginVersions: []
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

        // TODO when https://woocommerce.com/products/hardware/US and
        // https://woocommerce.com/products/hardware/CA are live, return the
        // following instead
        // URL(string: Constants.purchaseReaderForCountryUrlBase + self.countryCode) ?? Constants.fallbackInPersonPaymentsUrl

        return Constants.purchaseM2ReaderUrl
    }
}

private enum Constants {
    static let purchaseM2ReaderUrl = URL(string: "https://woocommerce.com/products/m2-card-reader/")!
    static let fallbackInPersonPaymentsUrl = URL(string: "https://woocommerce.com/in-person-payments/")!
    static let purchaseReaderForCountryUrlBase = "https://woocommerce.com/products/hardware/"
    static let stripeReaderPurchaseUrl = URL(string: "https://stripe.com/terminal/stripe-reader")!
}
