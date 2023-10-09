import Foundation
import Yosemite
import WooFoundation

class AboutTapToPayViewModel: ObservableObject {
    @Published var configuration: CardPresentPaymentsConfiguration
    private let buttonAction: (() -> Void)?

    @Published var shouldShowContactlessLimit: Bool = false
    @Published var shouldShowButton: Bool = false

    lazy var webViewModel: WebViewSheetViewModel = {
        WebViewSheetViewModel(
            url: WooConstants.URLs.inPersonPaymentsLearnMoreWCPayTapToPay.asURL(),
            navigationTitle: Localization.webViewTitle,
            authenticated: false)
    }()

    init(configuration: CardPresentPaymentsConfiguration,
         buttonAction: (() -> Void)?) {
        self.configuration = configuration
        self.buttonAction = buttonAction
        shouldShowButton = buttonAction != nil
        shouldShowContactlessLimit = configuration.contactlessLimitAmount != nil
    }

    func callToActionTapped() {
        buttonAction?()
    }
}

private extension AboutTapToPayViewModel {
    enum Localization {
        static let webViewTitle = NSLocalizedString(
            "About Tap to Pay",
            comment: "Title for the webview used by merchants to view more details about Tap to Pay on iPhone")
    }
}

class AboutTapToPayContactlessLimitViewModel: ObservableObject {
    private let configuration: CardPresentPaymentsConfiguration

    @Published private(set) var contactlessLimitDetails: String

    lazy var webViewModel: WebViewSheetViewModel = {
        WebViewSheetViewModel(
            url: configuration.purchaseCardReaderUrl(utmProvider:
                                                        WooCommerceComUTMProvider(
                                                            campaign: Constants.utmCampaign,
                                                            source: Constants.utmSource,
                                                            content: nil,
                                                            siteID: ServiceLocator.stores.sessionManager.defaultStoreID)),
            navigationTitle: Localization.webViewTitle,
            authenticated: true)
    }()

    init(configuration: CardPresentPaymentsConfiguration) {
        self.configuration = configuration
        self.contactlessLimitDetails = configuration.limitParagraph
    }

    func orderCardReaderPressed() {
        ServiceLocator.analytics.track(.aboutTapToPayOrderCardReaderTapped)
    }
}

private extension AboutTapToPayContactlessLimitViewModel {
    private enum Constants {
        static let utmCampaign = "about_tap_to_pay_contactless_limit"
        static let utmSource = "about_tap_to_pay"
    }

    private enum Localization {
        static let webViewTitle = NSLocalizedString(
            "Card Readers",
            comment: "Title for the webview used by merchants to place an order for a card reader, for use with " +
            "In-Person Payments.")
    }
}

private extension CardPresentPaymentsConfiguration {
    var localizedCountryName: String {
        // TODO: extract CountryCode and use it in the configuration
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
