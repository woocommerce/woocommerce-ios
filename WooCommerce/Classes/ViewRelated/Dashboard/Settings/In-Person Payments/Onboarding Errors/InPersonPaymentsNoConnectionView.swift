import SwiftUI

struct InPersonPaymentsNoConnection: View {
    let onRefresh: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(alignment: .center, spacing: 42) {
                Text(Localization.title)
                    .font(.headline)
                Image(uiImage: .errorStateImage)
                Text(Localization.message)
                    .font(.callout)
            }
            .multilineTextAlignment(.center)

            Spacer()

            Button(Localization.primaryButton, action: onRefresh)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 24.0)
        }
          .padding(24.0)
      }
}

private enum Localization {
      static let title = NSLocalizedString(
          "No connection",
          comment: "Title for the error screen when there was a network error checking In-Person Payments requirements."
      )

      static let message = NSLocalizedString(
          "A network error occurred. Please check your connection and try again.",
          comment: "Error message when there was a network error checking In-Person Payments requirements"
      )

    static let primaryButton = NSLocalizedString(
        "Retry",
        comment: "Button to retry when there was a network error checking In-Person Payments requirements"
    )
  }

struct InPersonPaymentsNoConnection_Previews: PreviewProvider {
    static var previews: some View {
        InPersonPaymentsNoConnection(onRefresh: {})
    }
}
