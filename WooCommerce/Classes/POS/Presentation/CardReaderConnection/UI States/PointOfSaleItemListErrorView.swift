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
        VStack(alignment: .center, spacing: 16) {
            Text("Products")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .font(.system(size: 40, weight: .bold, design: .default))
                .foregroundColor(Color.posPrimaryTexti3)
            Spacer()
            POSErrorExclamationMark()
            Text(errorContents.title)
                .foregroundStyle(Color.posPrimaryTexti3)
                .font(.posTitle)
                .bold()
            Divider()
                .padding([.leading, .trailing], 240)
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
            .padding([.leading, .trailing], 240)
            Spacer()
        }
    }
}
