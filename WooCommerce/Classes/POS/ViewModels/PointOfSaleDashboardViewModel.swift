import SwiftUI
import protocol Yosemite.POSItem
import struct Yosemite.POSProduct
import struct Yosemite.CartProduct
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published private(set) var products: [POSProduct]
    @Published private(set) var productsInCart: [CartProduct] = [] {
        didSet {
            calculateAmounts()
        }
    }
    @Published private(set) var formattedCartTotalPrice: String?
    @Published private(set) var formattedOrderTotalPrice: String?
    @Published private(set) var formattedOrderTotalTaxPrice: String?

    @Published var showsCardReaderSheet: Bool = false
    @Published var showsFilterSheet: Bool = false
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building
    
    private let currencyFormatter: CurrencyFormatter
    
    init(products: [POSItem],
         cardReaderConnectionViewModel: CardReaderConnectionViewModel,
         currencySettings: CurrencySettings) {
        // For the moment we inject POSItem, but only use the POSProduct implementation, since it's the only item type we're using
        // Later we might change this to support other types of items
        self.products = products.compactMap { $0 as? POSProduct }
        self.cardReaderConnectionViewModel = cardReaderConnectionViewModel
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        observeProductsInCartForCartTotal()
    }

    func addProductToCart(_ product: POSProduct) {
        let cartProduct = CartProduct(id: UUID(), product: product, quantity: 1)
        productsInCart.append(cartProduct)
    }

    // Removes a `CartProduct` from the Cart
    func removeProductFromCart(_ cartProduct: CartProduct) {
        productsInCart.removeAll(where: { $0.id == cartProduct.id })
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

    private func calculateAmounts() {
        // TODO: this is just a starting point for this logic, to have something calculated on the fly
        if let formattedCartTotalPrice = formattedCartTotalPrice,
           let subtotalAmount = currencyFormatter.convertToDecimal(formattedCartTotalPrice)?.doubleValue {
            let taxAmount = subtotalAmount * 0.1 // having fixed 10% tax for testing
            let totalAmount = subtotalAmount + taxAmount
            formattedOrderTotalTaxPrice = currencyFormatter.formatAmount(Decimal(taxAmount))
            formattedOrderTotalPrice = currencyFormatter.formatAmount(Decimal(totalAmount))
        }
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
