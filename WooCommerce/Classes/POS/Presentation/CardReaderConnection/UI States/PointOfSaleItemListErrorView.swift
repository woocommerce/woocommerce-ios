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
                    .font(.posTitleEmphasized)
                    .padding(.bottom, PointOfSaleItemListErrorLayout.verticalPadding)
                Text(error.subtitle)
                    .foregroundStyle(Color.posPrimaryText)
                    .font(.posBodyRegular)
                    .padding([.leading, .trailing])
                    .padding(.bottom, PointOfSaleItemListErrorLayout.verticalPadding)
                Button(action: {
                    onRetry?()
                }, label: {
                    Text(error.buttonText)
                })
                .buttonStyle(POSPrimaryButtonStyle())
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
