import SwiftUI
import protocol Yosemite.POSItem
import struct Yosemite.POSProduct
import struct Yosemite.CartItem
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class PointOfSaleDashboardViewModel: ObservableObject {
    @Published private(set) var items: [POSItem]
    @Published private(set) var itemsInCart: [CartItem] = [] {
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

    init(items: [POSItem],
         cardReaderConnectionViewModel: CardReaderConnectionViewModel,
         currencySettings: CurrencySettings) {
        self.items = items
        self.cardReaderConnectionViewModel = cardReaderConnectionViewModel
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        //observeProductsInCartForCartTotal()
    }

    func addItemToCart(_ item: POSItem) {
        let cartItem = CartItem(id: UUID(), item: item, quantity: 1)
        itemsInCart.append(cartItem)
    }

    func removeItemFromCart(_ cartItem: CartItem) {
        itemsInCart.removeAll(where: { $0.id == cartItem.id })
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
        PointOfSaleDashboardViewModel(items: [],
                                      cardReaderConnectionViewModel: .init(state: .connectingToReader),
                                      currencySettings: .init())
    }
}

private extension PointOfSaleDashboardViewModel {
//    func observeProductsInCartForCartTotal() {
//        $productsInCart
//            .map { [weak self] in
//                guard let self else { return nil }
//                let totalValue: Decimal = $0.reduce(0) { partialResult, cartProduct in
//                    let productPrice = self.currencyFormatter.convertToDecimal(cartProduct.product.price) ?? 0
//                    let quantity = cartProduct.quantity
//                    let total = productPrice.multiplying(by: NSDecimalNumber(value: quantity)) as Decimal
//                    return partialResult + total
//                }
//                return currencyFormatter.formatAmount(totalValue)
//            }
//            .assign(to: &$formattedCartTotalPrice)
//    }
}
