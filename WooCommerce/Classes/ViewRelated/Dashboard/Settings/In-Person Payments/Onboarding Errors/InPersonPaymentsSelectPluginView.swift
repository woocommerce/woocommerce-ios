import SwiftUI
import Yosemite

struct InPersonPaymentsSelectPlugin: View {
    let userIsAdministrator: Bool
    let onRefresh: () -> Void
    @State var presentedSetupURL: URL? = nil
    @Environment(\.verticalSizeClass) var verticalSizeClass

    var isCompact: Bool {
        get {
            verticalSizeClass == .compact
        }
    }

    var imageInfo: InPersonPaymentsOnboardingError.ImageInfo {
        get {
            .init(image: .paymentErrorImage, height: 24)
        }
    }

    var body: some View {
        ScrollableVStack {
            Spacer()

            VStack(alignment: .center) {
                Text(Localization.title)
                    .font(.headline)
                    .padding(.bottom, isCompact ? 16 : 32)
                Image(uiImage: imageInfo.image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: isCompact ? imageInfo.height / 3 : imageInfo.height)
                    .padding(.bottom, isCompact ? 16 : 32)
                Text(userIsAdministrator ? Localization.adminMessage : Localization.nonAdminMessage)
                    .font(.callout)
                    .padding(.bottom, isCompact ? 12 : 24)
                Text(CardPresentPaymentsPlugins.wcPay.pluginName)
                    .font(.callout)
                Text(Localization.conjunctiveOr)
                    .font(.body)
                Text(CardPresentPaymentsPlugins.stripe.pluginName)
                    .font(.callout)
                    .padding(.bottom, isCompact ? 12 : 24)
                InPersonPaymentsSupportLink()
            }.multilineTextAlignment(.center)
            .frame(maxWidth: 500)

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

    static let nonAdminMessage = NSLocalizedString(
        "In-Person Payments will only work with one of following plugins activated. Please contact a site administrator to deactivate one of these plugins to continue:",
        comment: "Message prompting a shop manager to ask an administrator to deactivate one of two plugins"
    )

    static let adminMessage = NSLocalizedString(
        "In-Person Payments will only work with one of following plugins activated. Please deactivate one of these plugins to continue:",
        comment: "Message prompting an administrator to deactivate one of two plugins"
    )

    static let conjunctiveOr = NSLocalizedString(
        "or",
        comment: "A single word displayed on a line by itself inbetween the names of two plugins"
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

struct InPersonPaymentsSelectPlugin_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsSelectPlugin(onRefresh: {})
    }
}
