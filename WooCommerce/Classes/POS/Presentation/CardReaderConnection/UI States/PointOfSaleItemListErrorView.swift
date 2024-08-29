import SwiftUI

struct PointOfSaleItemListErrorView: View {
    private var error: ItemListViewModel.ErrorModel
    private var onRetry: (() -> Void)? = nil

    init(error: ItemListViewModel.ErrorModel, onRetry: (() -> Void)? = nil) {
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
