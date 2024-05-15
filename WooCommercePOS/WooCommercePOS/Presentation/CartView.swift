import SwiftUI

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ProductRowView()
            ProductRowView()
            ProductRowView()
            Spacer()
            Button("Pay now") {
                viewModel.submitCart()
            }
        }
        .background(Color.secondaryBackground)
    }
}

#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts(),
                                                      cardReaderConnectionViewModel: .init(state: .connectingToReader)))
}
