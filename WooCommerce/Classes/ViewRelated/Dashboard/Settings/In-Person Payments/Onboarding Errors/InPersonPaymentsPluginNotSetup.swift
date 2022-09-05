import SwiftUI
import Yosemite

struct InPersonPaymentsPluginNotSetup: View {
    let plugin: CardPresentPaymentsPlugin
    let analyticReason: String
    private let cardPresentConfiguration = CardPresentConfigurationLoader().configuration
    let onRefresh: () -> Void
    @State private var presentedSetupURL: URL? = nil

    var body: some View {
        ScrollableVStack {
            Spacer()

            InPersonPaymentsOnboardingErrorMainContentView(
                title: String(format: Localization.title, plugin.pluginName),
                message: String(format: Localization.message, plugin.pluginName),
                image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                    image: plugin.image,
                    height: 108.0
                ),
                supportLink: false
            )

            Spacer()

            Button {
                presentedSetupURL = setupURL
                ServiceLocator.analytics.track(
                    event: WooAnalyticsEvent.InPersonPayments.cardPresentOnboardingCtaTapped(
                        reason: analyticReason,
                        countryCode: cardPresentConfiguration.countryCode))
            } label: {
                HStack {
                    Text(Localization.primaryButton)
                    Image(uiImage: .externalImage)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, 24.0)

            InPersonPaymentsLearnMore(viewModel: LearnMoreViewModel(tappedAnalyticEvent: learnMoreAnalyticEvent))
        }
        .safariSheet(url: $presentedSetupURL, onDismiss: onRefresh)
    }

    private var setupURL: URL? {
        guard let pluginSectionURL = ServiceLocator.stores.sessionManager.defaultSite?.pluginSettingsSectionURL(from: plugin) else {
            return nil
        }

        return URL(string: pluginSectionURL)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Finish setup for %1$@ in your store admin",
        comment: "Title for the error screen when an in-person payments plugin is active but not set up. %1$@ contains the plugin name."
    )

    static let message = NSLocalizedString(
        "You’re almost there! Please finish setting up %1$@ to start accepting In-Person Payments.",
        comment: "Error message when an in-person payments plugin is activated but not set up. %1$@ contains the plugin name."
    )

    static let primaryButton = NSLocalizedString(
        "Finish Setup in Store Admin",
        comment: "Button to set up an in-person payments plugin after activating it"
    )
}

struct InPersonPaymentsPluginNotSetup_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotSetup(plugin: .wcPay, analyticReason: "", onRefresh: {})
    }
}

private extension InPersonPaymentsPluginNotSetup {
    var learnMoreAnalyticEvent: WooAnalyticsEvent? {
        WooAnalyticsEvent.InPersonPayments.cardPresentOnboardingLearnMoreTapped(reason: analyticReason,
                                                                                countryCode: cardPresentConfiguration.countryCode)
    }
}
