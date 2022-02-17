import Foundation

public struct CardPresentPaymentsConfiguration {
    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [String]
    public let paymentGateways: [String]
    public let supportedReaders: [CardReaderType]
    public let purchaseCardReaderUrl: URL


    init(paymentMethods: [WCPayPaymentMethodType],
         currencies: [String],
         paymentGateways: [String],
         supportedReaders: [CardReaderType],
         purchaseCardReaderUrl: URL) {
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
        self.supportedReaders = supportedReaders
        self.purchaseCardReaderUrl = purchaseCardReaderUrl
    }

    public init(country: String, stripeEnabled: Bool, canadaEnabled: Bool) {
        switch country {
        case "US" where stripeEnabled == true:
            //TODO: update to use Self.purchaseCardReaderUrl(for: country) when pages/redirects are added to the website pdfdoF-su-p2
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2],
                purchaseCardReaderUrl: Constants.purchaseM2ReaderUrl
            )
        case "US" where stripeEnabled == false:
            //TODO: update to use Self.purchaseCardReaderUrl(for: country) when pages/redirects are added to the website pdfdoF-su-p2
            self.init(
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2],
                purchaseCardReaderUrl: Constants.purchaseM2ReaderUrl
            )
        case "CA" where canadaEnabled == true:
            self.init(
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: ["CAD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3],
                purchaseCardReaderUrl: Self.purchaseCardReaderUrl(for: country)
            )
        default:
            self.init(paymentMethods: [],
                      currencies: [],
                      paymentGateways: [],
                      supportedReaders: [],
                      purchaseCardReaderUrl: Constants.fallbackInPersonPaymentsUrl)
        }
    }

    public var isSupportedCountry: Bool {
        paymentMethods.isEmpty == false && currencies.isEmpty == false && paymentGateways.isEmpty == false
    }

    private static func purchaseCardReaderUrl(for countryCode: String) -> URL {
        URL(string: Constants.purchaseReaderForCountryUrlBase + countryCode) ?? Constants.fallbackInPersonPaymentsUrl
    }
}

private enum Constants {
    static let purchaseM2ReaderUrl = URL(string: "https://woocommerce.com/products/m2-card-reader/")!
    static let fallbackInPersonPaymentsUrl = URL(string: "https://woocommerce.com/in-person-payments/")!
    static let purchaseReaderForCountryUrlBase = "https://woocommerce.com/products/hardware/"
}
