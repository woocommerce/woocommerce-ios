import SwiftUI

struct PointOfSaleItemListErrorView: View {
    private var error: ItemListViewModel.ErrorModel
    private var onRetry: (() -> Void)? = nil

    init(error: ItemListViewModel.ErrorModel, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(alignment: .center, spacing: PointOfSaleItemListErrorLayout.headerSpacing) {
            POSHeaderTitleView(foregroundColor: .posIconGrayi3)
            Spacer()
            POSErrorExclamationMark()
            Text(error.title)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posTitle)
                .bold()
            Text(error.subtitle)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posBody)
                .padding([.leading, .trailing])
            Button(action: {
                onRetry?()
            }, label: {
                Text(error.buttonText)
            })
            .buttonStyle(POSPrimaryButtonStyle())
            .frame(width: PointOfSaleItemListErrorLayout.buttonWidth)
            Spacer()
        }
    }
}
