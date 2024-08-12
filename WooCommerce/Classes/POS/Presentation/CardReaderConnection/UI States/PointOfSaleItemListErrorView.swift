import SwiftUI

struct PointOfSaleItemListErrorView: View {
    private var viewModel: any ItemListViewModelProtocol

    init(viewModel: any ItemListViewModelProtocol) {
        self.viewModel = viewModel
    }

    var errorContents: ItemListViewModel.ErrorModel {
        guard let errorContents = viewModel.state.hasError else {
            return ItemListViewModel.ErrorModel(title: "Unknown error",
                                                subtitle: "Unknown error",
                                                buttonText: "Retry")
        }
        return errorContents
    }

    var body: some View {
        VStack(alignment: .center, spacing: Constants.headerSpacing) {
            Text(Localization.productTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Constants.headerPadding)
                .font(Constants.titleFont)
                .foregroundColor(Color.posPrimaryTexti3)
            Spacer()
            POSErrorExclamationMark()
            Text(errorContents.title)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posTitle)
                .bold()
            Text(errorContents.subtitle)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posBody)
                .padding([.leading, .trailing])
            Button(action: {
                Task {
                    await viewModel.reload()
                }
            }, label: {
                Text(errorContents.buttonText)
            })
            .buttonStyle(POSPrimaryButtonStyle())
            .padding([.leading, .trailing], Constants.buttonPadding)
            Spacer()
        }
    }
}

private extension PointOfSaleItemListErrorView {
    enum Localization {
        static let productTitle = NSLocalizedString(
            "pos.pointOfSaleItemListErrorView.productTitle",
            value: "Products",
            comment: "Title for the Point of Sale screen"
        )
    }
    enum Constants {
        static let headerPadding: CGFloat = 8
        static let headerSpacing: CGFloat = 16
        static let titleFont: Font = .system(size: 40, weight: .bold, design: .default)
        static let buttonPadding: CGFloat = 240
    }
}
