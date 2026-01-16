import SwiftUI

/// View for a single step in the POS Promotion modal.
///
struct POSPromotionStepView: View {
    private let viewModel: POSPromotionStepViewModel

    init(viewModel: POSPromotionStepViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: Layout.contentSpacing) {
            Image(viewModel.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: Layout.imageMaxHeight)
                .accessibilityHidden(true)

            Text(viewModel.title)
                .font(.title2)
                .bold()
                .multilineTextAlignment(.center)

            Text(viewModel.description)
                .font(.body)
                .foregroundStyle(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Layout.horizontalPadding)
    }
}

// MARK: - Layout Constants

private enum Layout {
    static let contentSpacing: CGFloat = 16
    static let imageMaxHeight: CGFloat = 210
    static let horizontalPadding: CGFloat = 16
}

// MARK: - Previews

#Preview {
    POSPromotionStepView(viewModel: .init(
        title: "Run POS with the WooCommerce mobile app",
        description: "Take payments in person and connect everything back to your store — all through the WooCommerce mobile app.",
        imageName: "pos-promotion-step-1"
    ))
}
