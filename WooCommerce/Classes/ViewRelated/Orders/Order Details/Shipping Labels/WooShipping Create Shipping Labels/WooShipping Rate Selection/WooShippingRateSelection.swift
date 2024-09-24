import SwiftUI

struct WooShippingRateSelection: View {
    var body: some View {
        VStack(spacing: Layout.verticalSpacing) {
            Image(.shippingLabelRatesPlaceholder)
                .padding(.bottom, Layout.imagePadding)
            Text(Localization.placeholderTitle)
                .font(.subheadline)
                .bold()
            Text(Localization.placeholderMessage)
                .subheadlineStyle()
        }
        .multilineTextAlignment(.center)
        .padding(.vertical, Layout.verticalPadding)
        .padding(.horizontal, Layout.horizontalPadding)
        .roundedBorder(cornerRadius: Layout.borderCornerRadius, lineColor: Color(.border), lineWidth: Layout.borderLineWidth, dashed: true)
    }
}

private extension WooShippingRateSelection {
    enum Layout {
        static let verticalSpacing: CGFloat = 8
        static let imagePadding: CGFloat = 24
        static let borderCornerRadius: CGFloat = 8
        static let borderLineWidth: CGFloat = 1
        static let verticalPadding: CGFloat = 40
        static let horizontalPadding: CGFloat = 32
    }

    enum Localization {
        static let placeholderTitle = NSLocalizedString(
            "wooShipping.createLabel.shippingRate.placeholderTitle",
            value: "Add a package to get shipping rates",
            comment: "Call to action in the shipping rate section during shipping label creation, when there is no selected package."
        )
        static let placeholderMessage = NSLocalizedString(
            "wooShipping.createLabel.shippingRate.placeholderMessage",
            value: "Enter your package's dimensions or pick a carrier package option to see the available shipping rates.",
            comment: "Message in the shipping rate section during shipping label creation, when there is no selected package."
        )
    }
}

#Preview {
    WooShippingRateSelection()
        .padding()
}
