import SwiftUI

struct PointOfSaleItemListErrorView: View {
    private var error: PointOfSaleErrorState
    private var onRetry: (() -> Void)? = nil

    init(error: PointOfSaleErrorState, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    var body: some View {
        PointOfSaleItemListFullscreenView {
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
                    .frame(width: PointOfSaleItemListErrorLayout.buttonWidth)
                }
                Spacer()
            }
        }
    }
}
