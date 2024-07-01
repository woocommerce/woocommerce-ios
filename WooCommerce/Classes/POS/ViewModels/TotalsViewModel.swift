import SwiftUI
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSItem
import struct Yosemite.POSCartItem
import struct Yosemite.POSOrder
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

final class TotalsViewModel: ObservableObject {
    /// Order created the first time the checkout is shown for a given transaction.
    /// If the merchant goes back to the product selection screen and makes changes, this should be updated when they return to the checkout.
    @Published private(set) var order: POSOrder?
    @Published private(set) var isSyncingOrder: Bool = false
    @Published private(set) var formattedCartTotalPrice: String?

    private let orderService: POSOrderServiceProtocol

    var formattedOrderTotalPrice: String? {
        formattedPrice(order?.total, currency: order?.currency)
    }

    var formattedOrderTotalTaxPrice: String? {
        formattedPrice(order?.totalTax, currency: order?.currency)
    }

    var showRecalculateButton: Bool {
        !areAmountsFullyCalculated &&
        isSyncingOrder == false
    }

    var areAmountsFullyCalculated: Bool {
        isSyncingOrder == false &&
        formattedOrderTotalTaxPrice != nil &&
        formattedOrderTotalPrice != nil
    }
    
    init(orderService: POSOrderServiceProtocol) {
        self.orderService = orderService
        // TODO:
        // - Inject cardPresentPaymentService
        // - Inject currencyFormatted
        // TODO:
        // - observe ConnectedReaderForStatus
        // - observe CardPresentPaymentEvents
    }

    func formattedPrice(_ price: String?, currency: String?) -> String? {
        guard let price, let currency else {
            return nil
        }
        // TODO:
        // Remove ServiceLocator dependency. Inject from the app through point of entry
        return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount(price, with: currency)
    }

    func startSyncOrder() {
        // TODO: 
        // Start & stop methods may no longer be needed, since sync state it's only internal
        isSyncingOrder = true
    }

    func stopSyncOrder() {
        isSyncingOrder = false
    }

    func clearOrder() {
        order = nil
    }

    func setOrder(updatedOrder: POSOrder) {
        order = updatedOrder
    }

    func calculateAmountsTapped(with cartItems: [CartItem], allItems: [POSItem]) {
        startSyncingOrder(with: cartItems, allItems: allItems)
    }

    func startSyncingOrder(with cartItems: [CartItem], allItems: [POSItem]) {
        Task { @MainActor in
            calculateCartTotal(cartItems: cartItems)
            await syncOrder(for: cartItems, allItems: allItems)
        }
    }

    @MainActor
    private func syncOrder(for cartProducts: [CartItem], allItems: [POSItem]) async {
        guard isSyncingOrder == false else {
            return
        }
        startSyncOrder()
        let cart = cartProducts
            .map {
                POSCartItem(itemID: nil,
                            product: $0.item,
                            quantity: Decimal($0.quantity))
            }
        defer {
            stopSyncOrder()
        }
        
        do {
            startSyncOrder()
            let order = try await orderService.syncOrder(cart: cart,
                                                         order: order,
                                                         allProducts: allItems)
            setOrder(updatedOrder: order)
            stopSyncOrder()
            // TODO: this is temporary solution
            // TODO: Move card present here as well.
            // await prepareConnectedReaderForPayment()
            DDLogInfo("🟢 [POS] Synced order: \(order)")
        } catch {
            DDLogError("🔴 [POS] Error syncing order: \(error)")
        }
    }

    private func calculateCartTotal(cartItems: [CartItem]) {
        formattedCartTotalPrice = { cartItems in
            let totalValue: Decimal = cartItems.reduce(0) { partialResult, cartItem in
                let itemPrice = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).convertToDecimal(cartItem.item.price) ?? 0
                let quantity = cartItem.quantity
                let total = itemPrice.multiplying(by: NSDecimalNumber(value: quantity)) as Decimal
                return partialResult + total
            }
            return CurrencyFormatter(currencySettings: ServiceLocator.currencySettings).formatAmount(totalValue)
        }(cartItems)
    }
}
