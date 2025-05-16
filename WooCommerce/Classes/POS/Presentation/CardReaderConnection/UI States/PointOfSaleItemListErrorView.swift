import SwiftUI

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
@available(iOS 17.0, *)
struct PointOfSaleItemListErrorView: View {
    @Environment(\.floatingControlAreaSize) private var floatingControlAreaSize: CGSize
    private let error: PointOfSaleErrorState
    private let onAction: (() -> Void)?

    @State private var viewWidth: CGFloat = 0

    @Environment(\.keyboardObserver) private var keyboard

    init(error: PointOfSaleErrorState, onAction: (() -> Void)? = nil) {
        self.error = error
        self.onAction = onAction
    }

    var body: some View {
        ScrollableVStack {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                if !keyboard.isFullSizeKeyboardVisible {
                    POSErrorExclamationMark(size: .large)

                    Spacer().frame(height: PointOfSaleCardPresentPaymentLayout.imageAndTextSpacing)
                }

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
        .padding(.bottom, !keyboard.isFullSizeKeyboardVisible ? floatingControlAreaSize.height : 0)
        .measureWidth { width in
            viewWidth = width
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleItemListErrorView(error: .errorOnLoadingProducts, onAction: nil)
}
