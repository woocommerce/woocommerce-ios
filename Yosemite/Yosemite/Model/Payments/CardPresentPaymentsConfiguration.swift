import Foundation
import WooFoundation

public struct CardPresentPaymentsConfiguration: Equatable {
    public let countryCode: String
    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [CurrencyCode]
    public let paymentGateways: [String]
    public let supportedReaders: [CardReaderType]
    public let supportedPluginVersions: [PaymentPluginVersionSupport]
    public let minimumAllowedChargeAmount: NSDecimalNumber
    public let stripeSmallestCurrencyUnitMultiplier: Decimal

    init(countryCode: String,
         paymentMethods: [WCPayPaymentMethodType],
         currencies: [CurrencyCode],
         paymentGateways: [String],
         supportedReaders: [CardReaderType],
         supportedPluginVersions: [PaymentPluginVersionSupport],
         minimumAllowedChargeAmount: NSDecimalNumber,
         stripeSmallestCurrencyUnitMultiplier: Decimal) {
        self.countryCode = countryCode
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
        self.supportedReaders = supportedReaders
        self.supportedPluginVersions = supportedPluginVersions
        self.minimumAllowedChargeAmount = minimumAllowedChargeAmount
        self.stripeSmallestCurrencyUnitMultiplier = stripeSmallestCurrencyUnitMultiplier
    }

    public init(country: String) {
        /// Changing `minimumVersion` values here? You'll need to also update `CardPresentPaymentsOnboardingUseCaseTests`
        switch country {
        case "US":
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.USD],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2, .appleBuiltIn],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: "3.2.1"),
                    .init(plugin: .stripe, minimumVersion: "6.2.0")
                ],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100
            )
        case "CA":
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: [.CAD],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.0.0")],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100
            )
        case "GB":
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.GBP],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.4.0")],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.3"),
                stripeSmallestCurrencyUnitMultiplier: 100
            )
        case "AU":
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.AUD],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.4.0")],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.3"),
                stripeSmallestCurrencyUnitMultiplier: 100
            )
        default:
            self.init(
                countryCode: country,
                paymentMethods: [],
                currencies: [],
                paymentGateways: [],
                supportedReaders: [],
                supportedPluginVersions: [],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100
            )
        }
    }

    public var isSupportedCountry: Bool {
        paymentMethods.isEmpty == false && currencies.isEmpty == false && paymentGateways.isEmpty == false && supportedReaders.isEmpty == false
    }

    /// Given a two character country code, returns a URL where the merchant can purchase a card reader.
    ///
    public func purchaseCardReaderUrl(utmProvider: UTMParametersProviding) -> URL {
        let urlString = Constants.purchaseReaderForCountryUrlBase + countryCode
        return utmProvider.urlWithUtmParams(string: urlString) ?? Constants.fallbackInPersonPaymentsUrl
    }
}

private enum Constants {
    static let fallbackInPersonPaymentsUrl = URL(string: "https://woocommerce.com/in-person-payments/")!
    static let purchaseReaderForCountryUrlBase = "https://woocommerce.com/products/hardware/"
}
