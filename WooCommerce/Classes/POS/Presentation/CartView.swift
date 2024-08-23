import SwiftUI
import protocol Yosemite.POSItem

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var cartViewModel: CartViewModel
    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    init(viewModel: PointOfSaleDashboardViewModel, cartViewModel: CartViewModel) {
        self.viewModel = viewModel
        self.cartViewModel = cartViewModel
    }

    var body: some View {
        VStack {
            DynamicHStack(spacing: Constants.cartHeaderSpacing) {
                HStack(spacing: Constants.cartHeaderElementSpacing) {
                    backAddMoreButton
                        .padding(.top, Constants.headerPadding)
                        .disabled(viewModel.isAddMoreDisabled)
                        .shimmering(active: viewModel.isAddMoreDisabled)

                    HStack {
                        Text(Localization.cartTitle)
                            .font(Constants.primaryFont)
                            .foregroundColor(cartViewModel.cartLabelColor)
                            .accessibilityAddTraits(.isHeader)

                        Spacer()

                        if let itemsInCartLabel = cartViewModel.itemsInCartLabel {
                            Text(itemsInCartLabel)
                                .font(Constants.itemsFont)
                                .foregroundColor(Color.posSecondaryTexti3)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .padding(.top, Constants.headerPadding)
                }

                HStack {
                    Spacer()
                        .renderedIf(dynamicTypeSize.isAccessibilitySize)

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
                    .padding(.top, Constants.headerPadding)
                    .renderedIf(cartViewModel.shouldShowClearCartButton)
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
                    Image(decorative: PointOfSaleAssets.shoppingBags.imageName)
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
                        .accessibilityAddTraits(.isHeader)
                }
            case .finalizing:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity)
        .background(cartViewModel.isCartEmpty ? Color.posBackgroundEmptyWhitei3.ignoresSafeArea(edges: .all) : Color.posBackgroundWhitei3.ignoresSafeArea(.all))
        .accessibilityElement(children: .contain)
    }
}

private extension CartView {
    enum Constants {
        static let primaryFont: POSFontStyle = .posTitleEmphasized
        static let secondaryFont: POSFontStyle = .posBodyRegular
        static let itemsFont: POSFontStyle = .posDetailRegular
        static let clearButtonFont: POSFontStyle = .posDetailEmphasized
        static let clearButtonCornerRadius: CGFloat = 4
        static let clearButtonBorderWidth: CGFloat = 2
        static let clearButtonTextPadding = EdgeInsets(top: 8, leading: 24, bottom: 8, trailing: 24)
        static let checkoutButtonPadding: CGFloat = 16
        static let itemHorizontalPadding: CGFloat = 8
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 8
        static let shoppingBagImageSize: CGFloat = 104
        static let cartEmptyViewSpacing: CGFloat = 40
        static let cartHeaderSpacing: CGFloat = 8
        static let backButtonSymbol: String = "chevron.backward"
        static let headerPadding: CGFloat = 16
        static let cartHeaderElementSpacing: CGFloat = 16
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
        static let checkoutButtonTitle = NSLocalizedString(
            "pos.cartView.checkoutButtonTitle",
            value: "Check out",
            comment: "Title for the 'Checkout' button to process the Order.")
    }
}

/// View sub-components
///
private extension CartView {
    var checkoutButton: some View {
        Button {
            cartViewModel.submitCart()
        } label: {
            Text(Localization.checkoutButtonTitle)
        }
        .buttonStyle(POSPrimaryButtonStyle())
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
                Image(systemName: Constants.backButtonSymbol)
                    .font(.posBodyEmphasized, maximumContentSizeCategory: .accessibilityLarge)
                    .foregroundColor(.primary)
            }
        }
    }
}

#if DEBUG
import Combine
import class WooFoundation.MockAnalyticsPreview
import class WooFoundation.MockAnalyticsProviderPreview

#Preview {
    // TODO:
    // Simplify this by mocking `CartViewModel`
    let totalsViewModel = TotalsViewModel(orderService: POSOrderPreviewService(),
                                          cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                          currencyFormatter: .init(currencySettings: .init()),
                                          paymentState: .acceptingCard)
    let cartViewModel = CartViewModel(analytics: MockAnalyticsPreview())
    let itemsListViewModel = ItemListViewModel(itemProvider: POSItemProviderPreview())
    let dashboardViewModel = PointOfSaleDashboardViewModel(cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                           totalsViewModel: totalsViewModel,
                                                           cartViewModel: cartViewModel,
                                                           itemListViewModel: itemsListViewModel,
                                                           connectivityObserver: POSConnectivityObserverPreview())
    return CartView(viewModel: dashboardViewModel, cartViewModel: cartViewModel)
}
#endif
