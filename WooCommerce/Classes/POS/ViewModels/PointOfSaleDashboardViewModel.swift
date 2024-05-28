import SwiftUI
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published private(set) var products: [POSProduct]
    @Published private(set) var productsInCart: [CartProduct] = []
    @Published private(set) var formattedCartTotalPrice: String?

    @Published var showsCardReaderSheet: Bool = false
    @Published var showsFilterSheet: Bool = false
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

    private let currencyFormatter: CurrencyFormatter

    init(products: [POSProduct],
         cardReaderConnectionViewModel: CardReaderConnectionViewModel,
         currencySettings: CurrencySettings) {
        self.products = products
        self.cardReaderConnectionViewModel = cardReaderConnectionViewModel
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        observeProductsInCartForCartTotal()
    }

    func addProductToCart(_ product: POSProduct) {
        if product.stockQuantity > 0 {
            reduceInventory(product)

            let cartProduct = CartProduct(id: UUID(), product: product, quantity: 1)
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
    // Helper function to populate SwifUI previews
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
