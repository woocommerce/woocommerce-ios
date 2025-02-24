import SwiftUI

/// A view that displays an error message with a retry CTA when the list of POS items fails to load.
struct PointOfSaleItemListErrorView: View {
    private let error: PointOfSaleErrorState
    private let onRetry: (() -> Void)?

    init(error: PointOfSaleErrorState, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center, spacing: POSSpacing.none) {
                POSErrorExclamationMark(size: .large)

                Spacer().frame(height: POSSpacing.large)

                Text(error.title)
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posHeadingBold)

                Spacer().frame(height: POSSpacing.small)

                Text(error.subtitle)
                    .foregroundStyle(Color.posOnSurface)
                    .font(.posBodyLargeRegular())
                    .padding([.leading, .trailing])

                Spacer().frame(height: POSSpacing.xxLarge)

                Button(action: {
                    onRetry?()
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
    PointOfSaleItemListErrorView(error: .errorOnLoadingProducts(), onRetry: nil)
}
