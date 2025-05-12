import SwiftUI
import enum Yosemite.POSItem

struct CartDetails: Decodable {
    let totals: Totals
    let coupons: [Coupon]?
    let paymentMethods: [String]

    enum CodingKeys: String, CodingKey {
        case totals
        case coupons
        case paymentMethods = "payment_methods"
    }
    
    struct Coupon: Decodable {
        let code: String?
        let discountType: String?
        let totals: Totals

        enum CodingKeys: String, CodingKey {
            case code
            case discountType = "discount_type"
            case totals
        }

        struct Totals: Decodable {
            let totalDiscount: String?
            let totalDiscountTax: String?
            let currencyCode: String?
            let currencySymbol: String?
            let currencyMinorUnit: Int?
            let currencyDecimalSeparator: String?
            let currencyThousandSeparator: String?
            let currencyPrefix: String?
            let currencySuffix: String?

            enum CodingKeys: String, CodingKey {
                case totalDiscount = "total_discount"
                case totalDiscountTax = "total_discount_tax"
                case currencyCode = "currency_code"
                case currencySymbol = "currency_symbol"
                case currencyMinorUnit = "currency_minor_unit"
                case currencyDecimalSeparator = "currency_decimal_separator"
                case currencyThousandSeparator = "currency_thousand_separator"
                case currencyPrefix = "currency_prefix"
                case currencySuffix = "currency_suffix"
            }
        }
    }

    struct Totals: Decodable {
        let totalItems: String?
        let totalItemsTax: String?
        let totalFees: String?
        let totalFeesTax: String?
        let totalDiscount: String?
        let totalDiscountTax: String?
        let totalShipping: String?
        let totalShippingTax: String?
        let totalPrice: String?
        let totalTax: String?

        let taxLines: [TaxLine]?
        let currencyCode: String?
        let currencySymbol: String?
        let currencyMinorUnit: Int?
        let currencyDecimalSeparator: String?
        let currencyThousandSeparator: String?
        let currencyPrefix: String?
        let currencySuffix: String?

        enum CodingKeys: String, CodingKey {
            case totalItems = "total_items"
            case totalItemsTax = "total_items_tax"
            case totalFees = "total_fees"
            case totalFeesTax = "total_fees_tax"
            case totalDiscount = "total_discount"
            case totalDiscountTax = "total_discount_tax"
            case totalShipping = "total_shipping"
            case totalShippingTax = "total_shipping_tax"
            case totalPrice = "total_price"
            case totalTax = "total_tax"
            case taxLines = "tax_lines"
            case currencyCode = "currency_code"
            case currencySymbol = "currency_symbol"
            case currencyMinorUnit = "currency_minor_unit"
            case currencyDecimalSeparator = "currency_decimal_separator"
            case currencyThousandSeparator = "currency_thousand_separator"
            case currencyPrefix = "currency_prefix"
            case currencySuffix = "currency_suffix"
        }

        struct TaxLine: Decodable {
            let name: String?
            let price: String?
            let rate: String?
        }
    }
}

final class CartDetailsViewModel: ObservableObject {
    @Published var cartDetails: String = "Loading..."
    @Published var cartToken: String?
    @Published var lastModified: String?
    @Published var errorMessage: String?

    var siteURL: String {
        ServiceLocator.stores.sessionManager.defaultSite?.url ?? ""
    }

    func addToCart(_ item: POSItem) async throws {
        switch item {
        case .simpleProduct(let product):
            let itemID = product.productID
            try await postAddItemToCart(itemID)
        case .variableParentProduct(let parentProduct):
            let itemID = parentProduct.productID
            // TODO
        case .variation(let variation):
            let itemID = variation.productID
            // TODO
        case .coupon(let coupon):
            let couponCode = coupon.code
            try await postAddCouponToCart(couponCode)
        }
    }

    func deleteCart() async throws {
        let endpoints = ["items", "coupons"]
        for endpoint in endpoints {
            guard let url = URL(string: "\(siteURL)/wp-json/wc/store/v1/cart/\(endpoint)") else {
                print("Invalid URL for \(endpoint)")
                continue
            }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            if let cartToken = cartToken {
                request.setValue(cartToken, forHTTPHeaderField: "Cart-Token")
            }

            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Deleted \(endpoint) with status: \(httpResponse.statusCode)")
            }
        }

        DispatchQueue.main.async {
            self.cartDetails = "Cart cleared."
        }
    }

    func fetchCartToken() async throws {
        guard let url = URL(string: "\(siteURL)/wp-json/wc/store/v1/cart") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (_, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            let headers = httpResponse.allHeaderFields
            if let cartTokenValue = headers.first(where: { "\($0.key)".lowercased() == "cart-token" })?.value as? String {
                print("🍍 \(cartTokenValue)")
                DispatchQueue.main.async {
                    self.cartToken = cartTokenValue
                }
            } else {
                print("❌ no token")
            }

            if let lastModifiedValue = headers.first(where: { "\($0.key)".lowercased() == "last-modified" })?.value as? String {
                print("🕒 \(lastModifiedValue)")
                DispatchQueue.main.async {
                    self.lastModified = lastModifiedValue
                }
            }
        }
    }

    private func postAddItemToCart(_ productID: Int64) async throws {
        guard let cartToken = cartToken else {
            print("❌ no token")
            return
        }

        guard let url = URL(string: "\(siteURL)/wp-json/wc/store/v1/cart/add-item") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(cartToken, forHTTPHeaderField: "Cart-Token")

        let body: [String: Any] = ["id": "\(productID)", "quantity": "1"]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        let details = try decoder.decode(CartDetails.self, from: data)
        print("""
        ✅ Cart Details Updated:
        - total_items: \(details.totals.totalItems ?? "N/A")
        - total_shipping: \(details.totals.totalShipping ?? "N/A")
        - total_shipping_tax: \(details.totals.totalShippingTax ?? "N/A")
        - total_price: \(details.totals.totalPrice ?? "N/A")
        - total_tax: \(details.totals.totalTax ?? "N/A")
        - tax_lines: \(details.totals.taxLines?.map { "\($0.name ?? "N/A"): \($0.price ?? "N/A") @ \($0.rate ?? "N/A")" }.joined(separator: ", ") ?? "N/A")
        - currency_code: \(details.totals.currencyCode ?? "N/A")
        - currency_symbol: \(details.totals.currencySymbol ?? "N/A")
        - currency_minor_unit: \(details.totals.currencyMinorUnit?.description ?? "N/A")
        - currency_decimal_separator: \(details.totals.currencyDecimalSeparator ?? "N/A")
        - currency_thousand_separator: \(details.totals.currencyThousandSeparator ?? "N/A")
        - currency_prefix: \(details.totals.currencyPrefix ?? "N/A")
        - currency_suffix: \(details.totals.currencySuffix ?? "N/A")
        """)

        DispatchQueue.main.async {
            let couponDetails = details.coupons?.map { coupon in
                "- code: \(coupon.code ?? "N/A"), discount_type: \(coupon.discountType ?? "N/A")"
            }.joined(separator: "\n") ?? "No coupons"

            self.cartDetails = """
            total_items: \(details.totals.totalItems ?? "N/A")
            total_shipping: \(details.totals.totalShipping ?? "N/A")
            total_shipping_tax: \(details.totals.totalShippingTax ?? "N/A")
            total_price: \(details.totals.totalPrice ?? "N/A")
            total_tax: \(details.totals.totalTax ?? "N/A")
            coupons:
            \(couponDetails)
            """
        }
    }

    private func postAddCouponToCart(_ code: String) async throws {
        guard let cartToken = cartToken else {
            print("❌ no token")
            return
        }

        guard let url = URL(string: "\(siteURL)/wp-json/wc/store/v1/cart/coupons?code=\(code)") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(cartToken, forHTTPHeaderField: "Cart-Token")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            let details = try decoder.decode(CartDetails.self, from: data)
            print("✅ Cart Details After Adding Coupon: \(details)")

            DispatchQueue.main.async {
                let couponDetails = details.coupons?.map { coupon in
                    "- code: \(coupon.code ?? "N/A"), discount_type: \(coupon.discountType ?? "N/A")"
                }.joined(separator: "\n") ?? "No coupons"

                self.cartDetails = """
                total_items: \(details.totals.totalItems ?? "N/A")
                total_shipping: \(details.totals.totalShipping ?? "N/A")
                total_shipping_tax: \(details.totals.totalShippingTax ?? "N/A")
                total_price: \(details.totals.totalPrice ?? "N/A")
                total_tax: \(details.totals.totalTax ?? "N/A")
                coupons:
                \(couponDetails)
                """
            }
        } else {
            if let errorResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let message = errorResponse["message"] as? String,
               let code = errorResponse["code"] as? String,
               let dataDict = errorResponse["data"] as? [String: Any] {

                let dataDescription = dataDict.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                let detailedErrorMessage = """
                Error:
                - Message: \(message)
                - Code: \(code)
                - Data: \(dataDescription)
                """
                print("❌ \(detailedErrorMessage)")

                DispatchQueue.main.async {
                    self.errorMessage = detailedErrorMessage
                }
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detailedErrorMessage])
            } else {
                let fallbackMessage = "Unknown error with status code \(httpResponse.statusCode)"
                print("❌ \(fallbackMessage)")
                DispatchQueue.main.async {
                    self.errorMessage = fallbackMessage
                }
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: fallbackMessage])
            }
        }
    }

    func fetchCartDetails() async throws {
        guard let url = URL(string: "\(siteURL)/wp-json/wc/store/v1/cart") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        let details = try decoder.decode(CartDetails.self, from: data)
        print("Parsed Cart Details: \(details)")
    }
}

struct CartDetailsView: View {
    @ObservedObject private var viewModel: CartDetailsViewModel

    init(viewModel: CartDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        if let error = viewModel.errorMessage {
            Text(error)
                .foregroundColor(.red)
                .padding()
        }
        VStack {
            Text(viewModel.cartDetails)
                .padding()
                .task {
                    do {
                        try await viewModel.fetchCartDetails()
                    } catch {
                        viewModel.errorMessage = error.localizedDescription
                    }
                }
        }
    }

    func getLatestCart() {
        Task {
            try? await viewModel.fetchCartDetails()
        }
    }
}

@available(iOS 17.0, *)
struct CartView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    private let viewHelper = CartViewHelper()

    @Environment(\.floatingControlAreaSize) var floatingControlAreaSize: CGSize
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    @State private var offSetPosition: CGFloat = 0.0
    @State private var cartContentHeight: CGFloat = 0.0
    @State private var scrollViewHeight: CGFloat = 0.0
    private var coordinateSpace: CoordinateSpace = .named(Constants.scrollViewCoordinateSpaceIdentifier)
    private var shouldApplyHeaderBottomShadow: Bool {
        posModel.cart.isNotEmpty && offSetPosition < 0
    }

    private var shouldApplyFooterTopShadow: Bool {
        let maxOffset = cartContentHeight - scrollViewHeight
        return posModel.cart.isNotEmpty &&
        cartContentHeight > scrollViewHeight &&
        abs(offSetPosition) < maxOffset
    }

    @State private var shouldShowItemImages: Bool = false

    private var shouldShowCoupons: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.enableCouponsInPointOfSale) && posModel.cart.coupons.isNotEmpty
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                POSPageHeaderView(title: Localization.cartTitle,
                                  backButtonConfiguration: backButtonConfiguration,
                                  trailingContent: {
                    DynamicHStack(horizontalAlignment: .trailing, verticalAlignment: .center, spacing: Constants.cartHeaderElementSpacing) {
                        if let itemsInCartLabel = viewHelper.itemsInCartLabel(for: posModel.cart.purchasableItems.count) {
                            Text(itemsInCartLabel)
                                .font(Constants.itemsFont)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                                .foregroundColor(Color.posOnSurfaceVariantLowest)
                        }

                        Button {
                            posModel.removeAllItemsFromCart()
                            ServiceLocator.analytics.track(.pointOfSaleClearCartTapped)
                            
                            Task {
                                try await posModel.cartDetailsVM.deleteCart()
                            }
                        } label: {
                            Text(Localization.clearButtonTitle)
                        }
                        .buttonStyle(POSOutlinedButtonStyle(size: .extraSmall))
                        .renderedIf(shouldShowClearCartButton)
                    }
                })
                .if(shouldApplyHeaderBottomShadow, transform: { $0.applyEdgeShadow(backgroundColor: backgroundColor, edges: .bottom) })
                .zIndex(1)

                if posModel.cart.isNotEmpty {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: Constants.cartItemSpacing) {
                                if shouldShowCoupons {
                                    couponsCartSectionView
                                }

                                ForEach(posModel.cart.purchasableItems, id: \.id) { cartItem in
                                    ItemRowView(cartItem: cartItem,
                                                showImage: $shouldShowItemImages,
                                                onItemRemoveTapped: posModel.orderStage == .building ? {
                                        ServiceLocator.analytics.track(.pointOfSaleItemRemovedFromCart)
                                        posModel.remove(cartItem: cartItem)
                                    } : nil)
                                    .id(cartItem.id)
                                    .transition(.opacity)
                                }
                            }
                            .padding(.bottom, Constants.cartLastItemBottomPadding)
                            .animation(Constants.cartAnimation, value: posModel.cart.purchasableItems.map(\.id))
                            .animation(Constants.cartAnimation, value: posModel.cart.coupons.map(\.id))
                            .background(GeometryReader { geometry in
                                Color.clear.preference(key: ScrollOffSetPreferenceKey.self,
                                                       value: geometry.frame(in: coordinateSpace).origin.y)
                                .preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
                                .onAppear {
                                    updateItemImageVisibility(cartListWidth: geometry.size.width)
                                }
                                .onChange(of: geometry.size.width) {
                                    updateItemImageVisibility(cartListWidth: $0)
                                }
                                .onChange(of: dynamicTypeSize) {
                                    updateItemImageVisibility(dynamicTypeSize: $0, cartListWidth: geometry.size.width)
                                }
                            })
                            .onPreferenceChange(ScrollOffSetPreferenceKey.self) { position in
                                self.offSetPosition = position
                            }
                            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                                self.cartContentHeight = height
                            }

                            Spacer()
                                .frame(height: floatingControlAreaSize.height)
                                .renderedIf(posModel.orderStage == .finalizing)
                        }
                        .background {
                            GeometryReader() { proxy in
                                Color.clear.preference(key: ScrollViewHeightPreferenceKey.self, value: proxy.size.height)
                            }
                        }
                        .onPreferenceChange(ScrollViewHeightPreferenceKey.self) { height in
                            self.scrollViewHeight = height
                        }
                        .coordinateSpace(name: Constants.scrollViewCoordinateSpaceIdentifier)
                        .onChange(of: posModel.cart.purchasableItems.first?.id) { itemToScrollTo in
                            if posModel.orderStage == .building {
                                withAnimation {
                                    proxy.scrollTo(itemToScrollTo)
                                }
                            }
                        }
                    }
                } else {
                    Spacer()
                }

                if viewHelper.shouldShowCheckout(orderStage: posModel.orderStage, cart: posModel.cart) {
                    CartDetailsView(viewModel: posModel.cartDetailsVM)
                    checkoutButton
                        .padding(.horizontal, POSHeaderLayoutConstants.sectionHorizontalPadding)
                        .padding(.vertical, Constants.checkoutButtonVerticalPadding)
                        .accessibilityAddTraits(.isHeader)
                        .if(shouldApplyFooterTopShadow, transform: { $0.applyEdgeShadow(backgroundColor: backgroundColor, edges: .top) })
                        .zIndex(1)
                }
            }
            .animation(Constants.cartAnimation, value: posModel.cart.isEmpty)
            .frame(maxWidth: .infinity)
            .background(content: {
                if posModel.cart.isEmpty {
                    cartEmptyView
                }
            })
            .background(backgroundColor.ignoresSafeArea(.all))
            .accessibilityElement(children: .contain)
        }
    }
}

private struct ScrollOffSetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { .zero }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // No-op
    }
}

private struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { .zero }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // No-op
    }
}

private struct ScrollViewHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat { .zero }

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // No-op
    }
}

@available(iOS 17.0, *)
private extension CartView {
    var backgroundColor: Color {
        .posSurfaceBright
    }

    var shouldPreventCartEditing: Bool {
        viewHelper.shouldPreventCartEditing(
            orderState: posModel.orderState,
            paymentState: posModel.paymentState)
    }

    var shouldShowClearCartButton: Bool {
        viewHelper.shouldShowClearCartButton(
            cart: posModel.cart,
            orderStage: posModel.orderStage)
    }

    func updateItemImageVisibility(dynamicTypeSize: DynamicTypeSize? = nil, cartListWidth: CGFloat) {
        let newVisibility = cartListWidth >= minimumWidthToShowItemImages(with: dynamicTypeSize ?? self.dynamicTypeSize)
        guard newVisibility != shouldShowItemImages else {
            return
        }
        shouldShowItemImages = newVisibility
    }

    func minimumWidthToShowItemImages(with dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small:
            240
        case .medium:
            260
        case .large:
            270
        case .xLarge:
            280
        case .xxLarge, .xxxLarge:
            300
        case .accessibility1:
            320
        case .accessibility2:
            400
        case .accessibility3, .accessibility4:
            420
        case .accessibility5:
            450
        @unknown default:
            450
        }
    }
}

@available(iOS 17.0, *)
private extension CartView {
    enum Constants {
        static let primaryFont: POSFontStyle = .posHeadingBold
        static let secondaryFont: POSFontStyle = .posBodyMediumRegular()
        static let itemsFont: POSFontStyle = .posBodySmallRegular()
        static let shoppingBagImageSize: CGFloat = 104
        static let scrollViewCoordinateSpaceIdentifier: String = "CartScrollView"
        static let emptyViewImageTextSpacing: CGFloat = POSSpacing.xLarge // This should be 40 by designs, but the overlay technique means we have to tweak it
        static let cartHeaderElementSpacing: CGFloat = POSSpacing.medium
        static let cartAnimation: Animation = .spring(duration: 0.2)
        static let checkoutButtonVerticalPadding: CGFloat = POSPadding.medium
        static let cartItemSpacing: CGFloat = POSSpacing.small
        static let cartLastItemBottomPadding: CGFloat = POSPadding.large
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
@available(iOS 17.0, *)
private extension CartView {
    var checkoutButton: some View {
        Button {
            Task { @MainActor in
                trackCheckoutTapped()
                await posModel.checkOut()
            }
        } label: {
            Text(Localization.checkoutButtonTitle)
        }
        .buttonStyle(POSFilledButtonStyle(size: .normal))
    }

    var backButtonConfiguration: POSPageHeaderBackButtonConfiguration? {
        switch posModel.orderStage {
        case .building:
            return nil
        case .finalizing:
            let state: POSPageHeaderBackButtonConfiguration.State = shouldPreventCartEditing ? .shimmering : .enabled
            return .init(state: state, action: {
                ServiceLocator.analytics.track(.pointOfSaleBackToCartTapped)
                posModel.addMoreToCart()
            })
        }
    }

    var cartEmptyView: some View {
        VStack {
            Spacer()
            // By designs, the text should be vertically centred with the image 40px above it.
            // SwiftUI doesn't allow us to absolutely pin a view to the centre then position other views relative to it
            // Instead, we can centre the text, and then put the image in an offset overlay. Offsetting from the top
            // avoids issues when the text size is changed through dynamic type.
            Text(Localization.addItemsToCartHint)
                .font(Constants.secondaryFont)
                .foregroundColor(Color.posOnSurfaceVariantLowest)
                .multilineTextAlignment(.center)
                .overlay(alignment: .top) {
                    Image(decorative: PointOfSaleAssets.shoppingBags.imageName)
                        .resizable()
                        .frame(width: Constants.shoppingBagImageSize, height: Constants.shoppingBagImageSize, alignment: .bottom)
                        .offset(y: -(Constants.shoppingBagImageSize + Constants.emptyViewImageTextSpacing))
                        .aspectRatio(contentMode: .fit)
                }
            Spacer()
        }
        .background(backgroundColor.ignoresSafeArea(.all))
    }

    var couponsCartSectionView: some View {
        VStack {
            ForEach(posModel.cart.coupons, id: \.id) { couponItem in
                CouponRowView(couponItem: couponItem,
                              couponRowState: viewHelper.couponRowState(orderStage: posModel.orderStage,
                                                                        orderState: posModel.orderState,
                                                                        couponItem: couponItem),
                              showImage: $shouldShowItemImages,
                              onItemRemoveTapped: posModel.orderStage == .building ? {
                    ServiceLocator.analytics.track(.pointOfSaleCouponRemovedFromCart)
                    posModel.remove(cartItem: couponItem)
                } : nil)
                .id(couponItem.id)
                .transition(.opacity)
            }
        }
    }
}

@available(iOS 17.0, *)
private extension CartView {
    func trackCheckoutTapped() {
        let purchasableItems = posModel.cart.purchasableItems.count
        let coupons = posModel.cart.coupons.count
        ServiceLocator.analytics.track(
            event: .PointOfSale.checkoutTapped(
                purchasableItemsInCart: purchasableItems,
                couponsInCart: coupons
            )
        )
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    CartView()
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}

@available(iOS 17.0, *)
#Preview("Cart with one item") {
    let posModel = POSPreviewHelpers.makePreviewAggregateModel()
    posModel.addToCart(.simpleProduct(.init(id: UUID(),
                                            name: "Sample Product",
                                            formattedPrice: "$10.00",
                                            productID: 6,
                                            price: "10")))
    return CartView()
        .environment(posModel)
}
#endif
