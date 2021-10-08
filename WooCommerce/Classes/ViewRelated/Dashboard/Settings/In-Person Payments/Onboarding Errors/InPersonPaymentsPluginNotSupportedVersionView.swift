import SwiftUI

struct InPersonPaymentsPluginNotSupportedVersion: View {
    let onRefresh: () -> Void

    var body: some View {
        ScrollableVStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.title)
                    .font(.headline)
                Image(uiImage: .paymentsPlugin)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 108.0)
                Text(Localization.message)
                    .font(.callout)
            }
            .multilineTextAlignment(.center)

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
        "Unsupported WooCommerce Payments version",
        comment: "Title for the error screen when the installed version of WooCommerce Payments is unsupported"
    )

    static let message = NSLocalizedString(
        "The WooCommerce Payments extension is installed on your store, but needs to be updated for In-Person Payments. "
            + "Please update WooCommerce Payments to the most recent version.",
        comment: "Error message when WooCommerce Payments is installed but the version is not supported"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Updating",
        comment: "Button to reload plugin data after updating the WooCommerce Payments plugin"
    )
}

struct InPersonPaymentsPluginNotSupportedVersion_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotSupportedVersion(onRefresh: {})
    }
}
