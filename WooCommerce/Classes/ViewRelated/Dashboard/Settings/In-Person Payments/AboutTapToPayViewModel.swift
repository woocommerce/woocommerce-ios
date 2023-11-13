import Foundation
import Yosemite
import WooFoundation

class AboutTapToPayViewModel: ObservableObject {
    let configuration: CardPresentPaymentsConfiguration
    private let cardReaderSupportDeterminer: CardReaderSupportDetermining

    @Published var shouldShowContactlessLimit: Bool = false
    @Published var shouldShowButton: Bool = false

    lazy var webViewModel: WebViewSheetViewModel = {
        WebViewSheetViewModel(
            url: WooConstants.URLs.inPersonPaymentsLearnMoreWCPayTapToPay.asURL(),
            navigationTitle: Localization.webViewTitle,
            authenticated: false)
    }()

    let siteID: Int64

    let formattedMinimumOperatingSystemVersionForTapToPay: String

    let cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol

    let shouldAlwaysHideSetUpTapToPayButton: Bool

    init(siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         configuration: CardPresentPaymentsConfiguration = CardPresentConfigurationLoader().configuration,
         cardReaderSupportDeterminer: CardReaderSupportDetermining? = nil,
         cardPresentPaymentsOnboardingUseCase: CardPresentPaymentsOnboardingUseCaseProtocol? = nil,
         shouldAlwaysHideSetUpTapToPayButton: Bool = false) {
        self.siteID = siteID
        self.configuration = configuration
        self.cardReaderSupportDeterminer = cardReaderSupportDeterminer ?? CardReaderSupportDeterminer(siteID: siteID, configuration: configuration)

        if let cardPresentPaymentsOnboardingUseCase {
            self.cardPresentPaymentsOnboardingUseCase = cardPresentPaymentsOnboardingUseCase
        } else {
            let onboardingUseCase = CardPresentPaymentsOnboardingUseCase()
            self.cardPresentPaymentsOnboardingUseCase = onboardingUseCase
            self.cardPresentPaymentsOnboardingUseCase.refresh()
        }

        self.shouldAlwaysHideSetUpTapToPayButton = shouldAlwaysHideSetUpTapToPayButton
        shouldShowContactlessLimit = configuration.contactlessLimitAmount != nil
        self.formattedMinimumOperatingSystemVersionForTapToPay = configuration.minimumOperatingSystemVersionForTapToPay.localizedFormattedString
        refreshButtonVisibility()
    }

    func setUpFlowDismissed() {
        refreshButtonVisibility()
    }

    private func refreshButtonVisibility() {
        guard !shouldAlwaysHideSetUpTapToPayButton else {
            return shouldShowButton = false
        }

        Task { @MainActor in
            let hasTapToPayUsage = await cardReaderSupportDeterminer.hasPreviousTapToPayUsage()
            shouldShowButton = !hasTapToPayUsage
        }
    }
}

private extension AboutTapToPayViewModel {
    enum Localization {
        static let webViewTitle = NSLocalizedString(
            "About Tap to Pay",
            comment: "Title for the webview used by merchants to view more details about Tap to Pay on iPhone")
    }
}

class AboutTapToPayContactlessLimitViewModel {
    private let configuration: CardPresentPaymentsConfiguration

    let contactlessLimitDetails: String

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
    var limitParagraph: String {
        guard let amount = formattedContactlessLimitAmount,
              countryCode == .GB else {
            // N.B. This is not ideal, because some countries have an article, e.g. 'the United States', and some don't.
            // Since it's a fallback, this is a fair trade off, but for the ideal string, the country name should be embedded.
            return String(format: Localization.contactlessLimitFallback, countryCode.readableCountry)
        }

        return String(format: Localization.contactlessLimitWithAmountGB, amount)
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
            "be replaced with the country name of the store, which is a trade off as it can't be contextually " +
            "translated, however this string is only used when there's a problem decoding the limit, so it's acceptable.")

        static let contactlessLimitWithAmountGB = NSLocalizedString(
            "In the United Kingdom, cards may only be used with Tap to Pay for transactions up to %1$@.",
            comment: "A description of the contactless limit, shown on the About Tap to Pay screen. This string is for " +
            "the UK specifically. %1$@ will be replaced with the limit amount in £ formatted correctly for the locale.")
    }
}
