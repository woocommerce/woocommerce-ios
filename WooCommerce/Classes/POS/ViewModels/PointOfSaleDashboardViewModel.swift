import Combine
import SwiftUI
import class Yosemite.PointOfSaleOrderService
import protocol Yosemite.PointOfSaleOrderServiceProtocol
import struct Yosemite.PointOfSaleOrder
import struct Yosemite.PointOfSaleCartItem
import struct Yosemite.PointOfSaleCartProduct
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published private(set) var products: [POSProduct]
    @Published private(set) var productsInCart: [CartProduct] = []
    @Published private(set) var formattedCartTotalPrice: String?
    var formattedOrderTotalPrice: String? {
        order?.total
    }
    var formattedOrderTotalTaxPrice: String? {
        order?.totalTax
    }

    @Published var showsCardReaderSheet: Bool = false
    @Published var showsFilterSheet: Bool = false
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

    @Published private var order: PointOfSaleOrder?
    @Published private var isSyncingOrder: Bool = false
    private let orderService: PointOfSaleOrderServiceProtocol
    private var cartSubscription: AnyCancellable?

    private let currencyFormatter: CurrencyFormatter

    init(products: [POSProduct],
         cardReaderConnectionViewModel: CardReaderConnectionViewModel,
         // TODO: DI to entry point from the app
         orderService: PointOfSaleOrderServiceProtocol = PointOfSaleOrderService(siteID: ServiceLocator.stores.sessionManager.defaultStoreID!,
                                                                                 credentials: ServiceLocator.stores.sessionManager.defaultCredentials!),
         currencySettings: CurrencySettings) {
        self.products = products
        self.cardReaderConnectionViewModel = cardReaderConnectionViewModel
        self.orderService = orderService
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        observeProductsInCartForCartTotal()
        observeProductsInCartForRemoteOrderSyncing()
    }

    func addProductToCart(_ product: POSProduct) {
        if product.stockQuantity > 0 {
            reduceInventory(product)

            let cartProduct = CartProduct(id: UUID(), cartItemID: nil, product: product, quantity: 1)
            productsInCart.append(cartProduct)
        } else {
            // TODO: Handle out of stock
            // wp.me/p91TBi-bcW#comment-12123
            return
        }
    }

    func reduceInventory(_ product: POSProduct) {
        guard let index = products.firstIndex(where: { $0.itemID == product.itemID }) else {
            return
        }
        let updatedQuantity = product.stockQuantity - 1
        let updatedProduct = product.createWithUpdatedQuantity(updatedQuantity)
        products[index] = updatedProduct
    }

    func restoreInventory(_ product: POSProduct) {
        guard let index = products.firstIndex(where: { $0.itemID == product.itemID }) else {
            return
        }
        let updatedQuantity = product.stockQuantity + 1
        let updatedProduct = product.createWithUpdatedQuantity(updatedQuantity)
        products[index] = updatedProduct
    }

    // Removes a `CartProduct` from the Cart
    func removeProductFromCart(_ cartProduct: CartProduct) {
        productsInCart.removeAll(where: { $0.id == cartProduct.id })

        // When removing an item from the cart, restore previous inventory
        guard let match = products.first(where: { $0.productID == cartProduct.product.productID }) else {
            return
        }
        restoreInventory(match)
    }

    func submitCart() {
        // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12810
        orderStage = .finalizing
    }

    func addMoreToCart() {
        orderStage = .building
    }

    func showCardReaderConnection() {
        showsCardReaderSheet = true
    }

    func showFilters() {
        showsFilterSheet = true
    }
}

extension PointOfSaleDashboardViewModel {
    // Helper function to populate SwiftUI previews
    static func defaultPreview() -> PointOfSaleDashboardViewModel {
        PointOfSaleDashboardViewModel(products: [],
                                      cardReaderConnectionViewModel: .init(state: .connectingToReader),
                                      currencySettings: .init())
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeProductsInCartForCartTotal() {
        $productsInCart
            .map { [weak self] in
                guard let self else { return nil }
                let totalValue: Decimal = $0.reduce(0) { partialResult, cartProduct in
                    let productPrice = self.currencyFormatter.convertToDecimal(cartProduct.product.price) ?? 0
                    let quantity = cartProduct.quantity
                    let total = productPrice.multiplying(by: NSDecimalNumber(value: quantity)) as Decimal
                    return partialResult + total
                }
                return currencyFormatter.formatAmount(totalValue)
            }
            .assign(to: &$formattedCartTotalPrice)
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeProductsInCartForRemoteOrderSyncing() {
        cartSubscription = Publishers.CombineLatest($productsInCart.debounce(for: .seconds(Constants.cartChangesDebounceDuration), scheduler: DispatchQueue.main),
                                                    $isSyncingOrder)
        .filter { _, isSyncingOrder in
            isSyncingOrder == false
        }
        .map { $0.0 }
        .removeDuplicates()
        .dropFirst()
        .sink { [weak self] cartProducts in
            Task { @MainActor in
                guard let self else {
                    throw OrderSyncError.selfDeallocated
                }
                let cart = cartProducts
                    .map {
                        PointOfSaleCartItem(itemID: $0.cartItemID,
                                            product: .init(productID: $0.product.productID, price: $0.product.price, productType: $0.product.productType),
                                            quantity: Decimal($0.quantity))
                    }
                defer {
                    self.isSyncingOrder = false
                }
                do {
                    self.isSyncingOrder = true
                    let posProducts = self.products.map { Yosemite.PointOfSaleCartProduct(productID: $0.productID, price: $0.price, productType: $0.productType) }
                    let order = try await self.orderService.syncOrder(cart: cart, order: self.order, allProducts: posProducts)
                    self.order = order
                    print("🟢 [POS] Synced order: \(order)")
                } catch {
                    print("🔴 [POS] Error syncing order: \(error)")
                }
            }
        }
    }
}

private extension PointOfSaleDashboardViewModel {
    enum Constants {
        static let cartChangesDebounceDuration: TimeInterval = 0.5
    }

    enum OrderSyncError: Error {
        case selfDeallocated
    }
}
