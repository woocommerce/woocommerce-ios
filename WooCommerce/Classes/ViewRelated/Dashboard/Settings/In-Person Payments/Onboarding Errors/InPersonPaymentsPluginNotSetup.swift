import SwiftUI
import Yosemite
import struct WooFoundation.ScrollableVStack

struct InPersonPaymentsPluginNotSetup: View {
    @ObservedObject var viewModel: InPersonPaymentsPluginNotSetupViewModel

    var body: some View {
        ScrollableVStack {
            Spacer()

            InPersonPaymentsOnboardingErrorMainContentView(
                title: String(format: Localization.title, viewModel.plugin.pluginName),
                message: String(format: Localization.message, viewModel.plugin.pluginName),
                secondaryMessage: nil,
                image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                    image: viewModel.plugin.image,
                    height: 108.0
                ),
                supportLink: false
            )

            Spacer()

            Button {
                viewModel.setupButtonTapped()
            } label: {
                HStack {
                    Text(Localization.primaryButton)
                    Image(uiImage: .externalImage)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            Button(Localization.refreshButton) {
                viewModel.onRefresh()
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.bottom, 24.0)

            InPersonPaymentsLearnMore(viewModel: LearnMoreViewModel(
                paymentGateway: viewModel.plugin,
                tappedAnalyticEvent: viewModel.learnMoreAnalyticEvent))
            .padding(.vertical, 8)
        }
        .sheet(item: $viewModel.presentedSetupURL, onDismiss: viewModel.onRefresh) { url in
            AuthenticatableWebView(url: url, title: Localization.primaryButton)
        }
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Finish setup for %1$@ in your store admin",
        comment: "Title for the error screen when an in-person payments plugin is active but not set up. %1$@ contains the plugin name."
    )

    static let message = NSLocalizedString(
        "You’re almost there! Please finish setting up %1$@ to start accepting In‑Person Payments.",
        comment: """
                 Error message when an in-person payments plugin is activated but not set up. %1$@ contains the plugin name.
                 The hyphen in "In‑Person" is a non-breaking hyphen (U+2011).
                 If your translation of that term also happens to contains a hyphen, please be sure to use the non-breaking hyphen character for it
                 """
    )

    static let primaryButton = NSLocalizedString(
        "Finish Setup in Store Admin",
        comment: "Button to set up an in-person payments plugin after activating it"
    )

    static let refreshButton = NSLocalizedString(
        "Refresh",
        comment: "Button to refresh the state of the in-person payments setup")
}

struct InPersonPaymentsPluginNotSetup_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotSetup(viewModel: InPersonPaymentsPluginNotSetupViewModel(plugin: .wcPay, analyticReason: "", onRefresh: {}))
    }
}
