import SwiftUI
import Yosemite

struct InPersonPaymentsDeactivateStripeAdmin: View {
    let onRefresh: () -> Void
    @State private var presentedSetupURL: URL? = nil
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var body: some View {
        ScrollableVStack {
            Spacer()

            InPersonPaymentsOnboardingError.MainContent(
                title: Localization.title,
                message: Localization.message,
                image: InPersonPaymentsOnboardingError.ImageInfo(
                    image: .paymentErrorImage,
                    height: 108.0
                ),
                supportLink: false
            )

            InPersonPaymentsSupportLink()

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
            .padding(.bottom, Constants.padding)

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
        "In-Person Payments are processed through WooCommerce Payments.",
        comment: "Title for the error screen when there is more than one plugin active " +
        "and the Stripe plugin should be deactivated"
    )

    static let message = NSLocalizedString(
        "Please deactivate WooCommerce Stripe Gateway to collect payments.",
        comment: "Message prompting an administrator to deactivate Stripe plugin"
    )

    static let primaryButton = NSLocalizedString(
        "Manage Plugins",
        comment: "Button to open browser to manage plugins"
    )
}

private enum Constants {
    static let height: CGFloat = 108.0
    static let padding: CGFloat = 24.0
}

struct InPersonPaymentsDeactivateStripeAdmin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginConflictAdmin(onRefresh: {})
    }
}
