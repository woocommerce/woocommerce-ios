import SwiftUI

struct InPersonPaymentsLiveSiteInTestMode: View {
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
        "WooCommerce Payments is in Test Mode",
        comment: "Title for the error screen when WooCommerce Payments is in test mode on a live site"
    )

    static let message = NSLocalizedString(
        "The WooCommerce Payments extension cannot be in test mode for In-Person Payments. "
            + "Please disable test mode.",
        comment: "Error message when WooCommerce Payments is in test mode on a live site"
    )

    static let primaryButton = NSLocalizedString(
        "Refresh After Updating",
        comment: "Button to reload plugin data after updating the WooCommerce Payments plugin settings"
    )
}

struct InPersonPaymentsLiveSiteInTestMode_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLiveSiteInTestMode(onRefresh: {})
    }
}
