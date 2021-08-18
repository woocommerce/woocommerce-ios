import SwiftUI

struct InPersonPaymentsUnavailable: View {
    var body: some View {
        ScrollableVStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.unavailable)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Image(uiImage: .paymentErrorImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180.0)
                Text(Localization.message)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            InPersonPaymentsLearnMore()
        }
    }
}

private enum Localization {
    static let unavailable = NSLocalizedString(
        "Unable to verify In-Person Payments for this store",
        comment: "Title for the error screen when In-Person Payments is unavailable"
    )

    static let message = NSLocalizedString(
        "We're sorry, we were unable to verify In-Person Payments for this store.",
        comment: "Generic error message when In-Person Payments is unavailable"
    )
}

struct InPersonPaymentsUnavailable_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsUnavailable()
    }
}
