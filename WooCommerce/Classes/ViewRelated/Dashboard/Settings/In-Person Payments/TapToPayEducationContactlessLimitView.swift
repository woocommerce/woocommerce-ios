import SwiftUI
import Yosemite
import WooFoundation

struct TapToPayEducationContactlessLimitView: View {
    let viewModel: TapToPayEducationContactlessLimitViewModel
    @State private var showingWebView: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            HStack {
                Image(systemName: "info.circle")
                Text(Localization.importantInformation)
            }
            .headlineStyle()
            Text(viewModel.contactlessLimitDetails)
            Text(Localization.overLimitSuggestion)
            Button(Localization.limitButtonTitle) {
                viewModel.orderCardReaderPressed()
                showingWebView = true
            }
            .buttonStyle(TextButtonStyle())
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(.wooCommercePurple(.shade0)))
        .cornerRadius(Layout.cornerRadius)
        .sheet(isPresented: $showingWebView) {
            WebViewSheet(viewModel: viewModel.webViewModel) {
                showingWebView = false
            }
        }
    }
}

private extension TapToPayEducationContactlessLimitView {
    enum Localization {
        static let importantInformation = NSLocalizedString(
            "Important information",
            comment: "Heading for the details pane showing the contactless limit on About Tap to Pay")

        static let overLimitSuggestion = NSLocalizedString(
            "tapToPay.aboutTapToPay.overLimitSuggestion",
            value: "To accept all payments above this limit, consider purchasing a card reader.",
            comment: "A suggestion to buy a hardware card reader to handle transactions above the contactless limit, " +
            "shown on the About Tap to Pay screen")

        static let limitButtonTitle = NSLocalizedString(
            "Learn more about card readers",
            comment: "A button to view more about hardware card readers to handle transactions above the contactless " +
            "limit, shown on the About Tap to Pay screen")
    }

    enum Layout {
        static let spacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
    }
}


final class TapToPayEducationContactlessLimitViewModel {
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

private extension TapToPayEducationContactlessLimitViewModel {
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
            "tapToPay.aboutTapToPay.contactlessLimit.gb",
            value: "In the United Kingdom, you can accept card payments with Tap to Pay for transactions up to %1$@. " +
            "For payments over %1$@, some cards allow customers to enter their PIN directly on the phone, " +
            "while others require a card reader to complete the payment.",
            comment: "A description of the contactless limit, shown on the About Tap to Pay screen. This string is for " +
            "the UK specifically. %1$@ will be replaced with the limit amount in £ formatted correctly for the locale."
        )
    }
}
