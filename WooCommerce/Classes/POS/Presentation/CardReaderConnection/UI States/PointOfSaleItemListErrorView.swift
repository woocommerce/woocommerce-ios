import SwiftUI

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
struct PointOfSaleItemListErrorView: View {
    private let error: PointOfSaleErrorState
    private let onAction: (() -> Void)?

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onAction = onAction
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                POSErrorExclamationMark(size: .large)

                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)

                Text(error.title)
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)

                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textSpacing)

                Text(error.subtitle)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .padding([.leading, .trailing])

                Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.textAndButtonSpacing)

                Button(action: {
                    onAction?()
                }, label: {
                    Text(error.buttonText)
                })
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .frame(maxWidth: PointOfSaleItemListErrorLayout.buttonWidth)
                .padding([.leading, .trailing])
            }
            Spacer()
        }
    }
}

#Preview {
    PointOfSaleItemListErrorView(error: .errorOnLoadingProducts(), onAction: nil)
}
