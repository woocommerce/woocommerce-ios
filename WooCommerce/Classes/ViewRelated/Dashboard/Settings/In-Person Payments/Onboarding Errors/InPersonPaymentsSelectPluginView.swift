import SwiftUI

struct InPersonPaymentsSelectPlugin: View {
    let onRefresh: () -> Void
    @State var presentedSetupURL: URL? = nil

    var body: some View {
        ScrollableVStack {
            Spacer()

            InPersonPaymentsOnboardingError.MainContent(
                title: Localization.title,
                message: Localization.message,
                image: InPersonPaymentsOnboardingError.ImageInfo(
                    image: .paymentsPlugin,
                    height: 108.0
                ),
                supportLink: false
            )

            Spacer()

            Button {
                presentedSetupURL = setupURL
            } label: {
                HStack {
                    Text(Localization.primaryButton)
                    Image(uiImage: .externalImage)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom, 24.0)

            InPersonPaymentsLearnMore()
        }
        .safariSheet(url: $presentedSetupURL, onDismiss: onRefresh)
    }

    var setupURL: URL? {
        guard let adminURL = ServiceLocator.stores.sessionManager.defaultSite?.adminURL else {
            return nil
        }

        return URL(string: adminURL)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Please select an extension",
        comment: "Title for the error screen when there is more than one extension active."
    )

    static let message = NSLocalizedString(
        "Choose between WooCommerce Payments and Stripe Extension",
        comment: "Message requesting merchants to select between available payments processors"
    )

    static let primaryButton = NSLocalizedString(
        "Select extension in Store Admin",
        comment: "Button to set up the WooCommerce Payments plugin after installing it"
    )
}

struct InPersonPaymentsSelectPlugin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsSelectPlugin(onRefresh: {})
    }
}
