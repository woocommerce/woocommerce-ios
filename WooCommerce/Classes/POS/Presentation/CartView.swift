import SwiftUI

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack {
                Text("Cart")
                Spacer()
                if let temsInCartLabel = viewModel.itemsInCartLabel {
                    Text(temsInCartLabel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            .font(.title)
            .foregroundColor(Color.white)
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(viewModel.itemsInCart, id: \.id) { cartItem in
                        ItemRowView(cartItem: cartItem) {
                            viewModel.removeItemFromCart(cartItem)
                        }
                        .id(cartItem.id)
                        .background(Color.tertiaryBackground)
                        .padding(.horizontal, 32)
                    }
                }
                .onChange(of: viewModel.itemToScrollToWhenCartUpdated?.id) { _ in
                    if viewModel.orderStage == .building,
                       let last = viewModel.itemToScrollToWhenCartUpdated?.id {
                        withAnimation {
                            proxy.scrollTo(last)
                        }
                    }
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
import class Yosemite.POSOrderService
import enum Yosemite.Credentials
#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                      cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                      orderService: POSOrderService(siteID: Int64.min,
                                                                                    credentials: Credentials(authToken: "token"))))
}
#endif
