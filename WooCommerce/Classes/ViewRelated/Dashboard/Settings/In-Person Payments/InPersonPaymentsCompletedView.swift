import SwiftUI

struct InPersonPaymentsCompleted: View {
    var body: some View {
        ScrollableVStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.title)
                    .font(.headline)
                Image(uiImage: .cardReaderConnect)
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
        "Account connected",
        comment: "Title when a payments account is successfully connected for Card Present Payments"
    )

    static let message = NSLocalizedString(
        "Taking you back to accept a payment",
        comment: "Message when a payments account is successfully connected for Card Present Payments"
    )
}

struct InPersonPaymentsCompleted_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsCompleted()
    }
}
