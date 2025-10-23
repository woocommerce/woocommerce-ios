import SwiftUI

/// Dismissable warning banner. Similar to StorePlanBanner but with dismiss capability.
///
struct DismissableWarningBanner: View {
    /// The warning message to display
    let message: String

    /// Closure invoked when the dismiss button is tapped
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: .zero) {
            Divider()

            HStack(alignment: .top, spacing: Layout.spacing) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color(.wooOrangeDark))
                    .accessibilityHidden(true)

                Text(message)
                    .bodyStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color(.textSubtle))
                }
                .accessibilityLabel(Localization.dismissAccessibilityLabel)
            }
            .padding()

            Divider()
        }
        .background(Color(.bannerBackground))
    }
}

// MARK: Definitions
private extension DismissableWarningBanner {
    enum Layout {
        static let spacing: CGFloat = 12
    }

    enum Localization {
        static let dismissAccessibilityLabel = NSLocalizedString(
            "dismissableWarningBanner.dismiss.accessibilityLabel",
            value: "Dismiss warning",
            comment: "Accessibility label for the dismiss button on a warning banner"
        )
    }
}

struct DismissableWarningBanner_Previews: PreviewProvider {
    static var previews: some View {
        DismissableWarningBanner(
            message: "Your site uses USD but your payment account uses GBP. This may cause payment issues.",
            onDismiss: {}
        )
        .previewLayout(.sizeThatFits)
    }
}
