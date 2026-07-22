import Foundation

struct InPersonPaymentsNoConnectionViewModel {
    let analyticReason: String
    let onRefresh: () -> Void

    var title: String {
        Localization.title
    }

    var message: String {
        Localization.message
    }

    var retryButtonTitle: String {
        Localization.primaryButton
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
