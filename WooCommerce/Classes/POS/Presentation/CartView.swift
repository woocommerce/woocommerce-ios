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
                    .padding(32)
            case .finalizing:
                addMoreButton
                    .padding(32)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.secondaryBackground)
    }
}

/// View sub-components
///
private extension CartView {
    private var checkoutButtonForegroundColor: Color {
        return viewModel.checkoutButtonDisabled ? Color.gray : Color.primaryBackground
    }

    private var checkoutButtonBackgroundColor: Color {
        return viewModel.checkoutButtonDisabled ? Color.white.opacity(0.5) : Color.white
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
        .disabled(viewModel.checkoutButtonDisabled)
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
    CartView(viewModel: PointOfSaleDashboardViewModel(items: POSProductProvider.provideProductsForPreview(),
                                                      currencySettings: .init(),
                                                      cardPresentPaymentService: CardPresentPaymentService(siteID: 0)))
}
#endif
