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
            VStack(alignment: .center) {
                POSErrorExclamationMark()
                    .padding(.bottom)
                Text(error.title)
                    .accessibilityAddTraits(.isHeader)
                    .foregroundStyle(Color.posPrimaryText)
                    .font(.posHeading)
                    .padding(.bottom, PointOfSaleItemListErrorLayout.verticalPadding)
                Text(error.subtitle)
                    .foregroundStyle(Color.posPrimaryText)
                    .font(.posBodyLargeRegular())
                    .padding([.leading, .trailing])
                    .padding(.bottom, PointOfSaleItemListErrorLayout.verticalPadding)
                Button(action: {
                    onRetry?()
                }, label: {
                    Text(error.buttonText)
                })
                .buttonStyle(POSButtonStyle(variant: .filled, size: .normal))
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
