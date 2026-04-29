import SwiftUI

struct AddCustomAmountView: View {
    @Binding var isPresented: Bool
    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            Text(Localization.title)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)

            Text(Localization.comingSoon)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantLowest)
                .multilineTextAlignment(.center)
        }
        .posModalCloseButton(action: {
            isPresented = false
        })
        .padding(POSPadding.xLarge)
        .background(Color.posSurfaceBright)
        .frame(
            maxWidth: parentSize.width * Constants.parentWidthRatio,
            maxHeight: parentSize.height * Constants.parentHeightRatio
        )
    }
}

private extension AddCustomAmountView {
    enum Constants {
        static let parentWidthRatio: CGFloat = 0.5
        static let parentHeightRatio: CGFloat = 0.5
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.addCustomAmount.title",
            value: "Add custom amount",
            comment: "Title of the sheet for adding a custom amount to the Point of Sale cart.")
        static let comingSoon = NSLocalizedString(
            "pos.addCustomAmount.comingSoon",
            value: "The custom amount form is coming soon.",
            comment: "Placeholder text shown on the Point of Sale add custom amount sheet while the form is under development.")
    }
}

#if DEBUG
#Preview {
    AddCustomAmountView(isPresented: .constant(true))
}
#endif
