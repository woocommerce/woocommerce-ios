import SwiftUI
import protocol Yosemite.POSItem

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel<TotalsViewModel>
    @ObservedObject private var cartViewModel: CartViewModel<TotalsViewModel>

    init(viewModel: PointOfSaleDashboardViewModel<TotalsViewModel>, cartViewModel: CartViewModel<TotalsViewModel>) {
        self.viewModel = viewModel
        self.cartViewModel = cartViewModel
    }

    var body: some View {
        VStack {
            HStack {
                Image(uiImage: .shoppingCartIcon)
                    .resizable()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .foregroundColor(.black)
                Text("Cart")
                    .font(Constants.primaryFont)
                    .foregroundColor(Color.posPrimaryTexti3)
                Spacer()
                if let temsInCartLabel = cartViewModel.itemsInCartLabel {
                    Text(temsInCartLabel)
                        .font(Constants.secondaryFont)
                        .foregroundColor(Color.posSecondaryTexti3)
                    Button {
                        cartViewModel.removeAllItemsFromCart()
                    } label: {
                        Text("Clear all")
                            .font(Constants.secondaryFont)
                            .foregroundColor(Color.init(uiColor: .wooCommercePurple(.shade60)))
                    }
                    .padding(.horizontal, 8)
                    .renderedIf(cartViewModel.canDeleteItemsFromCart)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 32)
            .padding(.vertical, 8)
            .font(.title)
            .foregroundColor(Color.white)
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(cartViewModel.itemsInCart, id: \.id) { cartItem in
                        ItemRowView(cartItem: cartItem,
                                    onItemRemoveTapped: cartViewModel.canDeleteItemsFromCart ? {
                            cartViewModel.removeItemFromCart(cartItem)
                        } : nil)
                        .id(cartItem.id)
                    }
                }
                .onChange(of: cartViewModel.itemToScrollToWhenCartUpdated?.id) { _ in
                    if viewModel.orderStage == .building,
                       let last = cartViewModel.itemToScrollToWhenCartUpdated?.id {
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
                    .disabled(viewModel.isAddMoreDisabled)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.posBackgroundWhitei3)
    }
}

private extension CartView {
    enum Constants {
        static let iconSize: CGFloat = 40
        static let primaryFont: Font = .system(size: 40, weight: .bold, design: .default)
        static let secondaryFont: Font = .system(size: 20, weight: .semibold, design: .default)
    }
}

/// View sub-components
///
private extension CartView {
    var checkoutButton: some View {
        Button {
            cartViewModel.submitCart()
        } label: {
            HStack {
                Spacer()
                Text("Checkout")
                    .font(.title)
                    .padding(20)
                Spacer()
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.primaryTint)
    }

    var addMoreButton: some View {
        Button {
            cartViewModel.addMoreToCart()
        } label: {
            Spacer()
            Text("Add More")
                .font(.title)
                .padding(20)
            Spacer()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.secondaryBackground)
    }
}

#if DEBUG
import Combine
#Preview {
    // TODO:
    // Simplify this by mocking `CartViewModel`
    // https://github.com/woocommerce/woocommerce-ios/issues/13207
    let orderStageSubject = PassthroughSubject<PointOfSaleDashboardViewModel<TotalsViewModel>.OrderStage, Never>()
    let orderStagePublisher = orderStageSubject.eraseToAnyPublisher()
    let dashboardViewModel = PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                                           cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                           totalsViewModel: TotalsViewModel(orderService: POSOrderPreviewService(),
                                                                                            cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                                                            currencyFormatter: .init(currencySettings: .init())))
    let cartViewModel = CartViewModel(orderStage: orderStagePublisher)

    return CartView(viewModel: dashboardViewModel, cartViewModel: cartViewModel)
}
#endif
