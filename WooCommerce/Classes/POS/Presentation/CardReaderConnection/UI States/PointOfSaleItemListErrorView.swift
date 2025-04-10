import SwiftUI

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
struct PointOfSaleItemListErrorView: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    private let error: PointOfSaleErrorState
    private let onAction: (() -> Void)?

    @State private var viewWidth: CGFloat = 0

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onAction = onAction
    }

    var body: some View {
        ScrollableVStack {
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
                .frame(width: viewWidth / 2)
                .padding([.leading, .trailing])
            }
            Spacer()
        }
        .padding(.bottom, floatingControlAreaSize.height)
        .measureWidth { width in
            viewWidth = width
        }
    }
}

#Preview {
    PointOfSaleItemListErrorView(error: .errorOnLoadingProducts, onAction: nil)
}
