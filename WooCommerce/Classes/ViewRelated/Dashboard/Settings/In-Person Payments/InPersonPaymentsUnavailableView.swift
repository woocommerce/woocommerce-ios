import SwiftUI

struct InPersonPaymentsUnavailableView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 42) {
            Text(Localization.unavailable)
                .font(.headline)
                .multilineTextAlignment(.center)
            Image(uiImage: .paymentErrorImage)
                .resizable()
                .scaledToFit()
                .frame(height: 180.0)
            Text(Localization.acceptCash)
                .font(.callout)
                .multilineTextAlignment(.center)
        }
        .padding(24.0)
    }
}

private enum Localization {
    static let unavailable = NSLocalizedString(
        "In-Person Payments is currently unavailable",
        comment: "Title for the error screen when In-Person Payments is unavailable"
    )

    static let acceptCash = NSLocalizedString(
        "You can still accept in-person cash payments by enabling the “Cash on Delivery” payment method on your store.",
        comment: "Generic error message when In-Person Payments is unavailable"
    )
}

struct InPersonPaymentsUnavailableView_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsUnavailableView()
    }
}
