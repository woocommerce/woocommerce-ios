import SwiftUI

struct OrderView: View {
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
                viewModel.callbackFromOrder()
            }
        }
    }
}

#Preview {
    OrderView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts()))
}
