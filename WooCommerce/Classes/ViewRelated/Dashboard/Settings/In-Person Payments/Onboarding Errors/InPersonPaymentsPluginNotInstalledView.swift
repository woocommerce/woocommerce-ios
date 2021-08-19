import SwiftUI

struct InPersonPaymentsPluginNotInstalled: View {
    let onRefresh: () -> Void

    var body: some View {
        ScrollableVStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Image(uiImage: .paymentsPlugin)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 126.0)
                Text(Localization.message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(Localization.primaryButton, action: onRefresh)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 24.0)
            InPersonPaymentsLearnMore()
        }
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Install WooCommerce Payments",
        comment: "Title for the error screen when WooCommerce Payments is not installed"
    )

    static let message = NSLocalizedString(
        "You’ll need to install the free WooCommerce Payments extension on your store to accept In-Person Payments.",
        comment: "Error message when WooCommerce Payments is not installed"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Installing",
        comment: "Button to reload plugin data after installing the WooCommerce Payments plugin"
    )
}

struct InPersonPaymentsPluginNotInstalled_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotInstalled(onRefresh: {})
    }
}
