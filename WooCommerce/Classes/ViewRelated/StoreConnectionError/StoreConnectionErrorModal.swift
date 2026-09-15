import SwiftUI

/// Tells the merchant that their store can't be reached and points them at support.
///
/// The scrim deliberately carries no tap gesture: the problem is on the merchant's site and needs their
/// attention, so the warning is left only through one of its two buttons.
///
struct StoreConnectionErrorModal: View {
    let onContactSupport: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.scrimOpacity)
                .ignoresSafeArea()

            // The card sizes to its content, and only scrolls when the content is taller than the screen,
            // as with the largest accessibility text sizes. A bare ScrollView would fill the whole height.
            ViewThatFits(in: .vertical) {
                content

                ScrollView {
                    content
                }
            }
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(Layout.cornerRadius)
            .shadow(radius: Layout.shadowRadius)
            .padding(Layout.modalPadding)
            .frame(maxWidth: Layout.maxWidth)
        }
        .accessibilityAddTraits(.isModal)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: Layout.spacing) {
            Text(Localization.title)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.text))
                .fixedSize(horizontal: false, vertical: true)

            Text(Localization.body)
                .font(.body)
                .foregroundStyle(Color(.text))
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: Layout.buttonSpacing) {
                Button(Localization.contactSupport, action: onContactSupport)
                    .buttonStyle(PrimaryButtonStyle())

                Button(Localization.dismiss, action: onDismiss)
                    .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.top, Layout.buttonsTopPadding)
        }
        .padding(Layout.contentPadding)
    }
}

/// Identifies the store connection warning to the Happiness Engineers picking up the ticket.
///
enum StoreConnectionErrorSupport {
    /// The origin of the support request, matching how the app tags its other support entry points.
    ///
    static let sourceTag = "origin:connection-error"

    /// The literal error identifier the Happiness Engineer playbook for this problem keys off. Written
    /// out rather than derived from the networking layer, because changing the error we detect must not
    /// silently change the tag those tickets are triaged by.
    ///
    static let additionalTags = ["rest_invalid_signature"]
}

private extension StoreConnectionErrorModal {
    enum Layout {
        static let scrimOpacity: CGFloat = 0.5
        static let spacing: CGFloat = 16
        static let buttonSpacing: CGFloat = 8
        static let buttonsTopPadding: CGFloat = 8
        static let contentPadding: CGFloat = 24
        static let modalPadding: CGFloat = 24
        static let cornerRadius: CGFloat = 10
        static let shadowRadius: CGFloat = 10
        static let maxWidth: CGFloat = 480
    }

    enum Localization {
        static let title = NSLocalizedString(
            "storeConnectionError.title",
            value: "Your store can't be reached",
            comment: "Title of the warning shown when the app cannot reach the merchant's store."
        )
        static let body = NSLocalizedString(
            "storeConnectionError.body",
            value: "We're having trouble connecting to your store. This is usually a connection issue on your WordPress site — " +
            "often caused by a security plugin, a recent plugin update, or a Jetpack connection that needs to be refreshed. " +
            "The WooCommerce app can't fix this from your phone.",
            comment: "Explanation shown when the app cannot reach the merchant's store because of a problem on their site."
        )
        static let contactSupport = NSLocalizedString(
            "storeConnectionError.contactSupport",
            value: "Contact support",
            comment: "Title of the button that opens the support form from the store connection warning."
        )
        static let dismiss = NSLocalizedString(
            "storeConnectionError.dismiss",
            value: "Dismiss",
            comment: "Title of the button that hides the store connection warning for the current session."
        )
    }
}

#Preview {
    StoreConnectionErrorModal(onContactSupport: {}, onDismiss: {})
}
