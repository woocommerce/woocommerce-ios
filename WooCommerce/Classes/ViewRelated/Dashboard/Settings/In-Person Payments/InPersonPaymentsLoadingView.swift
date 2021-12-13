import SwiftUI

struct InPersonPaymentsLoading: View {
    var body: some View {
        ScrollableVStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.title)
                    .font(.headline)
                Image(uiImage: .paymentsLoading)
                Text(Localization.message)
                    .font(.callout)
            }
            .multilineTextAlignment(.center)

            Spacer()
        }
    }
}

private enum Localization {
    static let title = NSLocalizedString(
        "Connecting to your account",
        comment: "Title when checking if WooCommerce Payments is supported"
    )

    static let message = NSLocalizedString(
        "Please wait",
        comment: "Message when checking if WooCommerce Payments is supported"
    )}

struct InPersonPaymentsLoading_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsLoading()
    }
}
