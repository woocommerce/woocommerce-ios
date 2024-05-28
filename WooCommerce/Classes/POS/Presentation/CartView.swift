import SwiftUI

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Cart")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .font(.title)
                .foregroundColor(Color.white)
            ScrollView {
                ForEach(viewModel.productsInCart, id: \.id) { cartProduct in
                    ProductRowView(cartProduct: cartProduct) {
                        viewModel.removeProductFromCart(cartProduct)
                    }
                    .background(Color.tertiaryBackground)
                    .padding(.horizontal, 32)
                }
            }
            Spacer()
            switch viewModel.orderStage {
            case .building:
                checkoutButton
                    .padding(.horizontal, 32)
            case .finalizing:
                addMoreButton
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.secondaryBackground)
    }
}

/// View sub-components
///
private extension CartView {
    var checkoutButton: some View {
        Button("Checkout") {
            viewModel.submitCart()
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, idealHeight: 120)
        .font(.title)
        .foregroundColor(Color.primaryBackground)
        .background(Color.white)
        .cornerRadius(10)
    }

    var addMoreButton: some View {
        Button("Add More") {
            viewModel.addMoreToCart()
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, idealHeight: 120)
        .font(.title)
        .foregroundColor(Color.white)
        .background(Color.secondaryBackground)
        .border(.white, width: 2)
        .cornerRadius(10)
    }
}

#if DEBUG
#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(products: POSProductFactory.makeFakeProducts(),
                                                      cardReaderConnectionViewModel: .init(state: .connectingToReader),
                                                      currencySettings: .init()))
}
#endif
