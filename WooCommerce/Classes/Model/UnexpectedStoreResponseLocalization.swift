import Foundation

enum UnexpectedStoreResponseLocalization {
    static let title = NSLocalizedString(
        "com.automattic.woocommerce.unexpectedStoreResponse.title",
        value: "Your store returned an unexpected server response.",
        comment: "Title shown when a store returns HTML or plain text instead of the response the app expects."
    )

    static let message = NSLocalizedString(
        "com.automattic.woocommerce.unexpectedStoreResponse.message",
        value: "The app could not load data from your store. This can happen when a server error, security service, " +
            "maintenance page, or rate limit blocks the store's REST API.",
        comment: "Explanation shown when a store returns HTML or plain text instead of the response the app expects."
    )

    static let contactSupport = NSLocalizedString(
        "com.automattic.woocommerce.unexpectedStoreResponse.contactSupport",
        value: "Contact Support",
        comment: "Button title that opens support for an unexpected store response."
    )

    static let dismiss = NSLocalizedString(
        "com.automattic.woocommerce.unexpectedStoreResponse.dismiss",
        value: "Dismiss",
        comment: "Button title that dismisses an unexpected store response alert."
    )
}
