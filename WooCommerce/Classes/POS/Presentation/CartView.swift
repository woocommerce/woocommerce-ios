import SwiftUI
import protocol Yosemite.POSItem

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var cartViewModel: CartViewModel

    init(viewModel: PointOfSaleDashboardViewModel, cartViewModel: CartViewModel) {
        self.viewModel = viewModel
        self.cartViewModel = cartViewModel
    }

    var body: some View {
        VStack {
            HStack {
                Text(Localization.cartTitle)
                    .font(Constants.primaryFont)
                    .foregroundColor(cartViewModel.cartLabelColor)
                Spacer()
                if let itemsInCartLabel = cartViewModel.itemsInCartLabel {
                    Text(itemsInCartLabel)
                        .font(Constants.secondaryFont)
                        .foregroundColor(Color.posSecondaryTexti3)
                    Button {
                        cartViewModel.removeAllItemsFromCart()
                    } label: {
                        Text(Localization.clearButtonTitle)
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
            if cartViewModel.itemsInCart.isEmpty {
                VStack {
                    Spacer()
                    Image(uiImage: .shoppingBagsImage)
                    Text(Localization.addItemsToCartHint)
                        .font(Constants.secondaryFont)
                        .foregroundColor(Color.posSecondaryTexti3)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
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
        static let primaryFont: Font = .system(size: 40, weight: .bold, design: .default)
        static let secondaryFont: Font = .system(size: 20, weight: .semibold, design: .default)
    }

    enum Localization {
        static let cartTitle = NSLocalizedString(
            "pos.cartView.cartTitle",
            value: "Cart",
            comment: "Title at the header for the Cart view.")
        static let clearButtonTitle = NSLocalizedString(
            "pos.cartView.clearButtonTitle",
            value: "Clear",
            comment: "Title for the 'Clear' button to remove all products from the Cart.")
        static let addItemsToCartHint = NSLocalizedString(
            "pos.cartView.addItemsToCartHint",
            value: "Tap on a product to \n add it to the cart",
            comment: "Hint to add products to the Cart when this is empty.")
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
    let orderStageSubject = PassthroughSubject<PointOfSaleDashboardViewModel.OrderStage, Never>()
    let orderStagePublisher = orderStageSubject.eraseToAnyPublisher()
    let dashboardViewModel = PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                                           cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                           orderService: POSOrderPreviewService(),
                                                           currencyFormatter: .init(currencySettings: .init()))
    let cartViewModel = CartViewModel(orderStage: orderStagePublisher)

    return CartView(viewModel: dashboardViewModel, cartViewModel: cartViewModel)
}
#endif
