import SwiftUI

struct InPersonPaymentsNoConnection: View {
    let analyticReason: String
    let onRefresh: () -> Void

    var body: some View {
        InPersonPaymentsOnboardingError(
            title: Localization.title,
            message: Localization.message,
            image: InPersonPaymentsOnboardingErrorMainContentView.ImageInfo(
                image: .errorStateImage,
                height: 108.0
            ),
            supportLink: false,
            learnMore: false,
            analyticReason: analyticReason,
            buttonViewModel: InPersonPaymentsOnboardingErrorButtonViewModel(
                text: Localization.primaryButton,
                analyticReason: analyticReason,
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
        InPersonPaymentsNoConnection(analyticReason: "", onRefresh: {})
    }
}
