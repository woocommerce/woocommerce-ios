import SwiftUI
import protocol Yosemite.POSItem

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var cartViewModel: CartViewModel
    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize

    init(viewModel: PointOfSaleDashboardViewModel, cartViewModel: CartViewModel) {
        self.viewModel = viewModel
        self.cartViewModel = cartViewModel
    }

    var body: some View {
        VStack {
            HStack {
                backAddMoreButton
                    .disabled(viewModel.isAddMoreDisabled)
                Text(Localization.cartTitle)
                    .font(Constants.primaryFont)
                    .foregroundColor(cartViewModel.cartLabelColor)
                Spacer()
                if let itemsInCartLabel = cartViewModel.itemsInCartLabel {
                    Text(itemsInCartLabel)
                        .font(Constants.itemsFont)
                        .foregroundColor(Color.posSecondaryTexti3)
                    Button {
                        cartViewModel.removeAllItemsFromCart()
                    } label: {
                        Text(Localization.clearButtonTitle)
                            .font(Constants.clearButtonFont)
                            .padding(Constants.clearButtonTextPadding)
                            .foregroundColor(Color.init(uiColor: .wooCommercePurple(.shade60)))
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.clearButtonCornerRadius)
                                    .stroke(Color.init(uiColor: .wooCommercePurple(.shade60)), lineWidth: Constants.clearButtonBorderWidth)
                            )
                    }
                    .padding(.horizontal, Constants.itemHorizontalPadding)
                    .renderedIf(cartViewModel.canDeleteItemsFromCart)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .font(.title)
            .foregroundColor(Color.white)
            if cartViewModel.isCartEmpty {
                VStack(spacing: Constants.cartEmptyViewSpacing) {
                    Spacer()
                    Image(uiImage: .shoppingBagsImage)
                        .resizable()
                        .frame(width: Constants.shoppingBagImageSize, height: Constants.shoppingBagImageSize)
                        .aspectRatio(contentMode: .fit)
                    Text(Localization.addItemsToCartHint)
                        .font(Constants.secondaryFont)
                        .foregroundColor(Color.posTertiaryTexti3)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(cartViewModel.itemsInCart, id: \.id) { cartItem in
                                ItemRowView(cartItem: cartItem,
                                            onItemRemoveTapped: cartViewModel.canDeleteItemsFromCart ? {
                                    cartViewModel.removeItemFromCart(cartItem)
                                } : nil)
                                .id(cartItem.id)
                            }
                        }
                        .padding(.bottom, floatingControlAreaSize.height)
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
                if cartViewModel.isCartEmpty {
                    EmptyView()
                } else {
                    checkoutButton
                        .padding(Constants.checkoutButtonPadding)
                }
            case .finalizing:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .background(cartViewModel.isCartEmpty ? Color.posBackgroundEmptyWhitei3.ignoresSafeArea(edges: .all) : Color.posBackgroundWhitei3.ignoresSafeArea(.all))
    }
}

private extension CartView {
    enum Constants {
        static let primaryFont: Font = .system(size: 40, weight: .bold, design: .default)
        static let secondaryFont: Font = .system(size: 24, weight: .regular, design: .default)
        static let itemsFont: Font = .system(size: 16, weight: .medium, design: .default)
        static let clearButtonFont: Font = .system(size: 16, weight: .semibold, design: .default)
        static let clearButtonCornerRadius: CGFloat = 4
        static let clearButtonBorderWidth: CGFloat = 2
        static let clearButtonTextPadding = EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24)
        static let checkoutButtonPadding: CGFloat = 16
        static let checkoutButtonHeight: CGFloat = 80
        static let itemHorizontalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let shoppingBagImageSize: CGFloat = 104
        static let cartEmptyViewSpacing: CGFloat = 40
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
                Text("Check out")
                Spacer()
            }
            .frame(minHeight: Constants.checkoutButtonHeight)
        }
        .buttonStyle(POSCheckoutButtonStyle())
    }

    @ViewBuilder
    var backAddMoreButton: some View {
        switch viewModel.orderStage {
        case .building:
            EmptyView()
        case .finalizing:
            Button {
                cartViewModel.addMoreToCart()
            } label: {
                Image(PointOfSaleAssets.posCartBackImageName)
                    .resizable()
                    .frame(width: 32, height: 32)
            }

        }
    }
}

struct POSCheckoutButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 24, weight: .bold))
            .background(Color.posCheckoutBackground)
            .foregroundColor(Color.white)
            .cornerRadius(8.0)
    }
}

#if DEBUG
import Combine
#Preview {
    // TODO:
    // Simplify this by mocking `CartViewModel`
    let totalsViewModel = TotalsViewModel(orderService: POSOrderPreviewService(),
                                          cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                          currencyFormatter: .init(currencySettings: .init()),
                                          paymentState: .acceptingCard,
                                          isSyncingOrder: false)
    let cartViewModel = CartViewModel()
    let itemsListViewModel = ItemListViewModel(itemProvider: POSItemProviderPreview())
    let dashboardViewModel = PointOfSaleDashboardViewModel(cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                           totalsViewModel: totalsViewModel,
                                                           cartViewModel: cartViewModel,
                                                           itemListViewModel: itemsListViewModel)
    return CartView(viewModel: dashboardViewModel, cartViewModel: cartViewModel)
}
#endif
