import SwiftUI

struct InPersonPaymentsWCPayNotSetup: View {
    let onRefresh: () -> Void
    @State var presentedSetupURL: URL? = nil

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.title)
                    .font(.headline)
                Image(uiImage: .paymentsPlugin)
                Text(Localization.message)
                    .font(.callout)
            }
            .multilineTextAlignment(.center)

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
        .padding(24.0)
        .safariSheet(url: $presentedSetupURL, onDismiss: onRefresh)
    }

    var setupURL: URL? {
        ServiceLocator.stores.sessionManager.defaultSite?.adminURL(path: Constants.wcpaySetupPath)
    }
}

private enum Constants {
    static let wcpaySetupPath = "wp-admin/admin.php?page=wc-admin&path=%2Fpayments%2Fconnect"
}

private enum Localization {
    static let title = NSLocalizedString(
        "Finish setup WooCommerce Payments in your store admin",
        comment: "Title for the error screen when WooCommerce Payments is installed but not set up"
    )

    static let message = NSLocalizedString(
        "You’re almost there! Please finish setting up WooCommerce Payments to start accepting Card-Present Payments.",
        comment: "Error message when WooCommerce Payments is installed but not set up"
    )

    static let primaryButton = NSLocalizedString(
        "Finish Setup in Store Admin",
        comment: "Button to set up the WooCommerce Payments plugin after installing it"
    )
}
struct InPersonPaymentsWCPayNotSetup_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsWCPayNotSetup(onRefresh: {})
    }
}
