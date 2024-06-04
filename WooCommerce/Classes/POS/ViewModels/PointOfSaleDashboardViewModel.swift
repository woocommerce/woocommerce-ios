import SwiftUI
import protocol Yosemite.POSItem
import struct Yosemite.POSProduct
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
    @Published private(set) var cardPresentPaymentEvent: CardPresentPaymentEvent = .idle
    @ObservedObject private(set) var cardReaderConnectionViewModel: CardReaderConnectionViewModel

    @Published var showsFilterSheet: Bool = false

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

    private let cardPresentPaymentService: CardPresentPaymentFacade

    private let currencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    init(items: [POSItem],
         cardPresentPaymentService: CardPresentPaymentFacade) {
        self.items = items
        self.cardPresentPaymentService = cardPresentPaymentService
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)
        observeCardPresentPaymentEvents()
        observeItemsInCartForCartTotal()
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
                                      cardPresentPaymentService: CardPresentPaymentService(siteID: 0))
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeItemsInCartForCartTotal() {
        $itemsInCart
            .map { [weak self] in
                guard let self else { return "-" }
                let totalValue: Decimal = $0.reduce(0) { partialResult, cartItem in
                    let itemPrice = self.currencyFormatter.convertToDecimal(cartItem.item.price) ?? 0
                    let quantity = cartItem.quantity
                    let total = itemPrice.multiplying(by: NSDecimalNumber(value: quantity)) as Decimal
                    return partialResult + total
                }
                return currencyFormatter.formatAmount(totalValue)
            }
            .assign(to: &$formattedCartTotalPrice)
    }

    func observeCardPresentPaymentEvents() {
        cardPresentPaymentService.paymentEventPublisher.assign(to: &$cardPresentPaymentEvent)
        cardPresentPaymentService.paymentEventPublisher.map { event in
            switch event {
            case .idle:
                return false
            case .showAlert,
                    .showReaderList,
                    .showOnboarding:
                return true
            }
        }.assign(to: &$showsCardReaderSheet)
    }
}
