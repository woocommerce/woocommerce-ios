import Foundation
import Yosemite
import WooFoundation

class AboutTapToPayViewModel: ObservableObject {
    @Published var configuration: CardPresentPaymentsConfiguration
    private let buttonAction: (() -> Void)?

    @Published var shouldShowContactlessLimit: Bool = false
    @Published var shouldShowButton: Bool = false

    init(configuration: CardPresentPaymentsConfiguration,
         buttonAction: (() -> Void)?) {
        self.configuration = configuration
        self.buttonAction = buttonAction
        shouldShowButton = buttonAction != nil
        shouldShowContactlessLimit = configuration.contactlessLimitAmount != nil
    }
}

class AboutTapToPayContactlessLimitViewModel: ObservableObject {
    private let configuration: CardPresentPaymentsConfiguration

    @Published private(set) var contactlessLimitDetails: String

    init(configuration: CardPresentPaymentsConfiguration) {
        self.configuration = configuration
        self.contactlessLimitDetails = configuration.limitParagraph
    }
}

private extension CardPresentPaymentsConfiguration {
    var localizedCountryName: String {
        guard let countryCode = SiteAddress.CountryCode(rawValue: countryCode) else {
            return self.countryCode
        }
        return countryCode.readableCountry
    }

    var limitParagraph: String {
        guard let amount = formattedContactlessLimitAmount else {
            return String(format: Localization.contactlessLimitFallback, localizedCountryName)
        }
        // TODO: make it "In the United Kingdom..." not just "In United Kingdom..."
        return String(format: Localization.contactlessLimitWithAmount, localizedCountryName, amount)
    }

    var formattedContactlessLimitAmount: String? {
        guard let contactlessLimitAmount,
              let currency = currencies.first?.rawValue else {
            return nil
        }
        let decimalLimit = Decimal(contactlessLimitAmount)/stripeSmallestCurrencyUnitMultiplier
        let formatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
        return formatter.formatAmount(decimalLimit, with: currency, numberOfDecimals: 0)
    }

    enum Localization {
        static let contactlessLimitFallback = NSLocalizedString(
            "In %1$@, cards may only be used with Tap to Pay for transactions up to the contactless limit.",
            comment: "A fallback describing the contactless limit, shown on the About Tap to Pay screen. %1$@ will " +
            "be replaced with the country name of the store.")

        static let contactlessLimitWithAmount = NSLocalizedString(
            "In %1$@, cards may only be used with Tap to Pay for transactions up to %2$@.",
            comment: "A description of the contactless limit, shown on the About Tap to Pay screen. %1$@ will " +
            "be replaced with the country name of the store, %2$@ with the limit amount in the local currency.")
    }
}
