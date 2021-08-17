import SwiftUI

struct InPersonPaymentsPluginNotActivated: View {
    let onRefresh: () -> Void

    var body: some View {
        VStack {
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
        .padding(24.0)
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Activate WooCommerce Payments",
        comment: "Title for the error screen when WooCommerce Payments is installed but not activated"
    )

    static let message = NSLocalizedString(
        "The WooCommerce Payments extension is installed on your store but not activated. Please activate it to accept In-Person Payments",
        comment: "Error message when WooCommerce Payments is not activated"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Activating",
        comment: "Button to reload plugin data after activating the WooCommerce Payments plugin"
    )
}

struct InPersonPaymentsPluginNotActivated_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsPluginNotActivated(onRefresh: {})
    }
}
