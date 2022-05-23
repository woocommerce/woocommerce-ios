import SwiftUI
import Yosemite

struct InPersonPaymentsDeactivateStripeShopManagerView: View {
    let onRefresh: () -> Void
    @State private var presentedSetupURL: URL? = nil
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompact: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

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

            InPersonPaymentsLearnMore()
        }
        .safariSheet(url: $presentedSetupURL, onDismiss: onRefresh)
    }

    private var setupURL: URL? {
        guard let adminURL = ServiceLocator.stores.sessionManager.defaultSite?.adminURL else {
            return nil
        }

        return URL(string: adminURL)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "In-Person Payments are processed through WooCommerce Payments.",
        comment: "Title for the error screen when there is more than one plugin active" +
        "that supports in-person payments and Stripe is not supported in that country."
    )

    static let message = NSLocalizedString(
        "Please contact a site administrator to deactivate WooCommerce Stripe Gateway to collect payments.",
        comment: "Message prompting an administrator to deactivate Stripe plugin"
    )
}

private enum Constants {
    static let height: CGFloat = 108.0
    static let padding: CGFloat = 24.0
}

struct InPersonPaymentsDeactivateStripeShopManager_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginConflictShopManager(onRefresh: {})
    }
}
