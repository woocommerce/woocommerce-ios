import SwiftUI

struct InPersonPaymentsStripeRejected: View {
    var body: some View {
          VStack {
              Spacer()

              VStack(alignment: .center, spacing: 42) {
                  Text(Localization.title)
                      .font(.headline)
                  Image(uiImage: .paymentErrorImage)
                      .resizable()
                      .scaledToFit()
                      .frame(height: 180.0)
                  Text(Localization.message)
                      .font(.callout)
                  InPersonPaymentsSupportLink()
              }
              .multilineTextAlignment(.center)

              Spacer()

              InPersonPaymentsLearnMore()
          }
          .padding(24.0)
      }
}

private enum Localization {
      static let title = NSLocalizedString(
          "In-Person Payments isn't available for this store",
          comment: "Title for the error screen when the Stripe account rejected."
      )

      static let message = NSLocalizedString(
          "We are sorry but we can't support In-Person Payments for this store.",
          comment: "Error message when WooCommerce Payments is not supported because the Stripe account has been rejected"
      )
  }

struct InPersonPaymentsStripeRejected_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsStripeRejected()
    }
}
