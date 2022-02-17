import Foundation

public struct CardPresentPaymentsConfiguration {
    public let countryCode: String?
    public let paymentMethods: [WCPayPaymentMethodType]
    public let currencies: [String]
    public let paymentGateways: [String]
    public let supportedReaders: [CardReaderType]

    init(countryCode: String?, paymentMethods: [WCPayPaymentMethodType], currencies: [String], paymentGateways: [String], supportedReaders: [CardReaderType]) {
        self.countryCode = countryCode
        self.paymentMethods = paymentMethods
        self.currencies = currencies
        self.paymentGateways = paymentGateways
        self.supportedReaders = supportedReaders
    }

    public init(country: String, stripeEnabled: Bool, canadaEnabled: Bool) {
        switch country {
        case "US" where stripeEnabled == true:
            self.init(
                countryCode: "US",
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID, StripeAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2]
            )
        case "US" where stripeEnabled == false:
            self.init(
                countryCode: "US",
                paymentMethods: [.cardPresent],
                currencies: ["USD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.chipper, .stripeM2]
            )
        case "CA" where canadaEnabled == true:
            self.init(
                countryCode: "CA",
                paymentMethods: [.cardPresent, .interacPresent],
                currencies: ["CAD"],
                paymentGateways: [WCPayAccount.gatewayID],
                supportedReaders: [.wisepad3]
            )
        default:
            self.init(countryCode: nil, paymentMethods: [], currencies: [], paymentGateways: [], supportedReaders: [])
        }
    }

    public var isSupportedCountry: Bool {
        countryCode != nil
    }

    public static var unsupported: CardPresentPaymentsConfiguration {
        .init(countryCode: nil, paymentMethods: [], currencies: [], paymentGateways: [], supportedReaders: [])
    }
}

open class CardPresentConfigurationLoaderInterface: ObservableObject {
    @Published var configuration: CardPresentPaymentsConfiguration = .unsupported
    @Published var state: CardPresentPaymentOnboardingState = .loading

    public init() {}
}
