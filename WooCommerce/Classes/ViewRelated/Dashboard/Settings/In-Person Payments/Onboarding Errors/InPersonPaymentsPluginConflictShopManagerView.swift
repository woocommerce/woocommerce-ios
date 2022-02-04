import SwiftUI
import Yosemite

struct InPersonPaymentsPluginConfictShopManager: View {
    let onRefresh: () -> Void
    @State var presentedSetupURL: URL? = nil
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

            InPersonPaymentsPluginChoicesView()

            // TODO Support

            Spacer()

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
        "Conflicting payment plugins detected",
        comment: "Title for the error screen when there is more than one plugin active that supports in-person payments."
    )

    static let message = NSLocalizedString(
        "In-Person Payments will only work with one of following plugins activated. Please contact a site administrator to deactivate one of these plugins to continue:",
        comment: "Message prompting a shop manager to ask an administrator to deactivate one of two plugins"
    )
}

private enum Constants {
    static let height: CGFloat = 108.0
    static let padding: CGFloat = 24.0
}

struct InPersonPaymentsPluginConfictShopManager_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginConfictShopManager(onRefresh: {})
    }
}

