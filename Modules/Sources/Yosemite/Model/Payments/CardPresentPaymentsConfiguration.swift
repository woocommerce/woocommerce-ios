import Foundation
import WooFoundation

public struct CardPresentPaymentsConfiguration: Equatable {
    public let countryCode: CountryCode
    public let paymentMethods: [PaymentMethodType]
    public let currencies: [CurrencyCode]
    public let paymentGateways: [String]
    public let supportedReaders: [CardReaderType]
    public let supportedPluginVersions: [PaymentPluginVersionSupport]
    public let minimumAllowedChargeAmount: NSDecimalNumber
    public let stripeSmallestCurrencyUnitMultiplier: Decimal

    /// `contactlessLimitAmount` is the upper limit for card transactions, expressed in the smallest currency unit.
    /// This limit may have different implications depending on the store's territory.
    public let contactlessLimitAmount: Int?

    /// `minimumOperatingSystemVersionOverride` allows us to override Stripe's `supportsReaders` check
    /// such that if it returns `true`, we additionally check for the user's phone meeting this version.
    /// Stripe bumped the Tap to Pay minimum to iOS 18.0.1 (September 2025).
    /// This usage can be removed if Stripe make `supportsReaders` location aware
    public let minimumOperatingSystemVersionForTapToPay: OperatingSystemVersion

    init(countryCode: CountryCode,
         paymentMethods: [PaymentMethodType],
         currencies: [CurrencyCode],
         paymentGateways: [String],
         supportedReaders: [CardReaderType],
         supportedPluginVersions: [PaymentPluginVersionSupport],
         minimumAllowedChargeAmount: NSDecimalNumber,
         stripeSmallestCurrencyUnitMultiplier: Decimal,
         contactlessLimitAmount: Int?,
         minimumOperatingSystemVersionForTapToPay: OperatingSystemVersion) {
        self.countryCode = countryCode
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
        self.supportedReaders = supportedReaders
        self.supportedPluginVersions = supportedPluginVersions
        self.minimumAllowedChargeAmount = minimumAllowedChargeAmount
        self.stripeSmallestCurrencyUnitMultiplier = stripeSmallestCurrencyUnitMultiplier
        self.contactlessLimitAmount = contactlessLimitAmount
        self.minimumOperatingSystemVersionForTapToPay = minimumOperatingSystemVersionForTapToPay
    }

    public init(country: CountryCode) {
        /// Changing `minimumVersion` values here? You'll need to also update `CardPresentPaymentsOnboardingUseCaseTests`
        ///
        /// This initializer describes Stripe Terminal capabilities for the given country.
        /// The decision of whether IPP/POS should be *exposed* to the merchant is gated
        /// upstream by `CardPresentConfigurationLoader` and the IPP entry points, which
        /// consult the country expansion eligibility cache (RSM-637) before consuming
        /// this configuration.
        switch country {
        case .US:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.USD],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2, .tapToPay],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: "3.2.1"),
                    .init(plugin: .stripe, minimumVersion: "6.2.0")
                ],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100,
                contactlessLimitAmount: nil,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
            )
        case .PR:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.USD],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: "9.0.0")
                ],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100,
                contactlessLimitAmount: nil,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
            )
        case .CA:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: [.CAD],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [.init(plugin: .wcPay, minimumVersion: "4.0.0")],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100,
                contactlessLimitAmount: 25000,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
            )
        case .GB:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.GBP],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.wisepad3, .tapToPay],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: "4.4.0"),
                    .init(plugin: .stripe, minimumVersion: "6.2.0")
                ],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.3"),
                stripeSmallestCurrencyUnitMultiplier: 100,
                contactlessLimitAmount: 10000,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
            )
        case .AT, .BE, .FI, .FR, .DE, .IE, .IT, .LU, .NL, .PT, .ES:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.EUR],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: "4.4.0"),
                    .init(plugin: .stripe, minimumVersion: "6.2.0")
                ],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100,
                // €50 — Stripe Terminal contactless CVM limit, shared by all
                // EEA-Euro countries we support (see https://docs.stripe.com/terminal/features/contactless).
                contactlessLimitAmount: 5000,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
            )
        case .SG:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.SGD],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: "4.4.0"),
                    .init(plugin: .stripe, minimumVersion: "6.2.0")
                ],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100,
                // Stripe Terminal's published contactless limits don't include SG
                // (see https://docs.stripe.com/terminal/features/contactless), so
                // we leave this `nil` to match the US/PR shape and let the reader
                // apply its own scheme limits.
                contactlessLimitAmount: nil,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
            )
        case .NZ:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.NZD],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: "4.4.0"),
                    .init(plugin: .stripe, minimumVersion: "6.2.0")
                ],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100,
                // NZD 200 — Stripe Terminal contactless CVM limit
                // (see https://docs.stripe.com/terminal/features/contactless).
                contactlessLimitAmount: 20000,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
            )
        case .AU:
            self.init(
                countryCode: country,
                paymentMethods: [.cardPresent],
                currencies: [.AUD],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3],
                supportedPluginVersions: [
                    .init(plugin: .wcPay, minimumVersion: Constants.minimumWCPayVersionForTerminalPaymentPreparation)
                ],
                minimumAllowedChargeAmount: NSDecimalNumber(string: "0.5"),
                stripeSmallestCurrencyUnitMultiplier: 100,
                // AUD 200 — Stripe Terminal contactless CVM limit
                contactlessLimitAmount: 20000,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
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
                stripeSmallestCurrencyUnitMultiplier: 100,
                contactlessLimitAmount: nil,
                minimumOperatingSystemVersionForTapToPay: Constants.sharedMinimumIosVersion
            )
        }
    }

    public var isSupportedCountry: Bool {
        paymentMethods.isEmpty == false && currencies.isEmpty == false && paymentGateways.isEmpty == false && supportedReaders.isEmpty == false
    }

    /// Given a two character country code, returns a URL where the merchant can purchase a card reader.
    ///
    public func purchaseCardReaderUrl(utmProvider: UTMParametersProviding) -> URL {
        let urlString = Constants.purchaseReaderForCountryUrlBase + countryCode.rawValue
        return utmProvider.urlWithUtmParams(string: urlString) ?? Constants.fallbackInPersonPaymentsUrl
    }
}

private enum Constants {
    static let fallbackInPersonPaymentsUrl = URL(string: "https://woocommerce.com/in-person-payments/")!
    static let purchaseReaderForCountryUrlBase = "https://woocommerce.com/products/hardware/"
    static let sharedMinimumIosVersion = OperatingSystemVersion(majorVersion: 18, minorVersion: 0, patchVersion: 1)
    static let minimumWCPayVersionForTerminalPaymentPreparation = "10.8.0-test-1"
}

/// The `@retroactive` attribute is used to apply `Equatable` conformance to `OperatingSystemVersion` from the Foundation module.
/// This is necessary due to Swift 6 [SE-0364 proposal](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0364-retroactive-conformance-warning.md).
extension OperatingSystemVersion: @retroactive Equatable {
    public static func == (lhs: OperatingSystemVersion, rhs: OperatingSystemVersion) -> Bool {
        return lhs.majorVersion == rhs.majorVersion &&
        lhs.minorVersion == rhs.minorVersion &&
        lhs.patchVersion == rhs.patchVersion
    }
}
