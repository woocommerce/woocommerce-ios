import StoreDesignSystem
import SwiftUI

struct HTTPSConfigurationWarningBanner: View {
    let onAction: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        StoreNoticeBanner(HTTPSConfigurationWarningContent.title,
                          description: HTTPSConfigurationWarningContent.message,
                          tone: .warning,
                          icon: StoreIcon.CircleInfo.regular,
                          actionTitle: HTTPSConfigurationWarningContent.actionTitle,
                          action: onAction,
                          dismissAccessibilityLabel: HTTPSConfigurationWarningContent.dismissAccessibilityLabel,
                          onDismiss: onDismiss)
            .frame(maxWidth: 720)
            .padding(.horizontal, StorePadding.p4)
            .padding(.vertical, StorePadding.p3)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
    }
}

enum HTTPSConfigurationWarningContent {
    static let title = NSLocalizedString(
        "https-configuration-warning.title",
        value: "Secure your store with HTTPS",
        comment: "Title of a persistent warning shown when a store reports an HTTP site address."
    )
    static let message = NSLocalizedString(
        "https-configuration-warning.https-supported-message",
        value: "Your store supports HTTPS, but its address is configured to use HTTP. " +
        "Update it to HTTPS to protect your store and prevent connection problems.",
        comment: "Message in a persistent warning explaining that a merchant should configure their store address to use HTTPS."
    )
    static let actionTitle = NSLocalizedString(
        "https-configuration-warning.learn-more",
        value: "Learn more",
        comment: "Button title that opens documentation about configuring HTTPS for a WooCommerce store."
    )
    static let dismissAccessibilityLabel = NSLocalizedString(
        "https-configuration-warning.dismiss",
        value: "Dismiss",
        comment: "Accessibility label for dismissing the HTTPS configuration warning."
    )
    static let helpURL = "https://woocommerce.com/document/ssl-and-https/#for-new-websites-stores"
}
