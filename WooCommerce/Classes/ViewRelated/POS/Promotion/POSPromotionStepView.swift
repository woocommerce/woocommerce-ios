import SwiftUI

/// View for the text content of a single step in the POS Promotion modal.
/// The image is displayed separately to avoid animating during page transitions.
///
struct POSPromotionStepTextView: View {
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: Layout.contentSpacing) {
            Text(title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text(description)
                .font(.body)
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Layout Constants

private enum Layout {
    static let contentSpacing: CGFloat = 16
}

// MARK: - Previews

#Preview {
    POSPromotionStepTextView(
        title: "Run POS with the WooCommerce mobile app",
        description: "Take payments in person and connect everything back to your store — all through the WooCommerce mobile app."
    )
}
