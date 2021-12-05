import SwiftUI

struct InPersonPaymentsNoConnection: View {
    let onRefresh: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingError.ImageInfo(
                image: .errorStateImage,
                height: 108.0
            ),
            supportLink: false,
            learnMore: false,
            button: InPersonPaymentsOnboardingError.ButtonInfo(
                text: Localization.primaryButton,
                action: onRefresh
            )
        )
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
