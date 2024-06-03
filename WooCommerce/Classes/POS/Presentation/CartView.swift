import class Yosemite.POSProductProvider
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
                ForEach(viewModel.itemsInCart, id: \.id) { cartItem in
                    ItemRowView(cartItem: cartItem) {
                        viewModel.removeItemFromCart(cartItem)
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
    // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12917
    // The Yosemite.POSProductProvider import is only needed for previews
    CartView(viewModel: PointOfSaleDashboardViewModel(items: POSProductProvider.provideProductsForPreview(),
                                                      cardReaderConnectionViewModel: .init(state: .connectingToReader),
                                                      currencySettings: .init()))
}
#endif
