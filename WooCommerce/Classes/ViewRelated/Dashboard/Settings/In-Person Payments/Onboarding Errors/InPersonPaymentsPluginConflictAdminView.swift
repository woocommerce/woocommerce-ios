import SwiftUI

struct InPersonPaymentsPluginConfictAdmin: View {
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
        "Conflicting payment plugins detected",
        comment: "Title for the error screen when there is more than one plugin active that supports in-person payments."
    )

    static let message = NSLocalizedString(
        "In-Person Payments will only work with one of following plugins activated. Please deactivate one of these plugins to continue:",
        comment: "Message prompting an administrator to deactivate one of two plugins"
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

struct InPersonPaymentsPluginConfictAdmin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginConfictAdmin(onRefresh: {})
    }
}
