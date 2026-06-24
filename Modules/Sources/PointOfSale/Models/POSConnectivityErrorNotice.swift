import Foundation

enum POSConnectivityErrorNotice {
    static let title = NSLocalizedString(
        "pos.connectivity.title",
        value: "No internet connection",
        comment: "Title shown when Point of Sale has no internet connection"
    )

    static let subtitle = NSLocalizedString(
        "pos.itemList.connectivityErrorSubtitle",
        value: "Please check your internet connection and try again.",
        comment: "Subtitle appearing on error screens when there is a network connectivity error."
    )
}
