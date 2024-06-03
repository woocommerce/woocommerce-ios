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
                ForEach(viewModel.productsInCart, id: \.product.productID) { cartProduct in
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
    private var checkoutButtonDisabled: Bool {
        return viewModel.productsInCart.isEmpty
    }

    private var checkoutButtonForegroundColor: Color {
        return checkoutButtonDisabled ? Color.gray : Color.primaryBackground
    }

    private var checkoutButtonBackgroundColor: Color {
        return checkoutButtonDisabled ? Color.white.opacity(0.5) : Color.white
    }

    var checkoutButton: some View {
        Button {
            viewModel.submitCart()
        } label: {
            HStack {
                Spacer()
                Text("Checkout")
                Spacer()
            }
        }
        .disabled(viewModel.productsInCart.isEmpty)
        .padding(.all, 20)
        .frame(maxWidth: .infinity, idealHeight: 120)
        .font(.title)
        .foregroundColor(checkoutButtonForegroundColor)
        .background(checkoutButtonBackgroundColor)
        .cornerRadius(10)
    }

    var addMoreButton: some View {
        Button {
            viewModel.addMoreToCart()
        } label: {
            Spacer()
            Text("Add More")
            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, idealHeight: 120)
        .font(.title)
        .foregroundColor(Color.white)
        .background(Color.secondaryBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white, lineWidth: 2)
        )
    }
}

#if DEBUG
#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(products: POSProductProvider.provideProductsForPreview(),
                                                      currencySettings: .init(),
                                                      cardPresentPaymentService: CardPresentPaymentService(siteID: 0)))
}
#endif
