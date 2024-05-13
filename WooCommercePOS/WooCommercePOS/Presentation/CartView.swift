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
    }
}

#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts()))
}
