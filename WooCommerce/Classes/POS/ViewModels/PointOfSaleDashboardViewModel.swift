import SwiftUI
import Yosemite
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import Combine

final class PointOfSaleDashboardViewModel: ObservableObject {
    enum OrderStage {
        case building
        case finalizing
    }

    let itemSelectorViewModel: ItemSelectorViewModel
    private(set) lazy var cartViewModel: CartViewModel = CartViewModel(orderStage: $orderStage.eraseToAnyPublisher())
    let totalsViewModel: TotalsViewModel
    let cardReaderConnectionViewModel: CardReaderConnectionViewModel

    @Published private(set) var orderStage: OrderStage = .building
    @Published private(set) var isCartCollapsed: Bool = true

    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false

    private var subscriptions: Set<AnyCancellable> = []

    init(itemProvider: POSItemProvider,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter) {
        self.itemSelectorViewModel = .init(itemProvider: itemProvider)
        self.totalsViewModel = .init(orderService: orderService,
                                     cardPresentPaymentService: cardPresentPaymentService,
                                     currencyFormatter: currencyFormatter)
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)

        observeSelectedItemToAddToCart()
        observeCartAddMoreTaps()
        observeCartSubmissions()
        observeCartItemsForCollapsedState()
        observePaymentStateForButtonDisabledProperties()
    }

    private func startSyncingOrder(cartItems: [CartItem]) {
        totalsViewModel.startSyncingOrder(itemsInCart: cartItems, allItems: itemSelectorViewModel.items)
    }

    func startNewTransaction() {
        // Q: Do we need 2 cart methods if removing all items already implies moving to .building state?
        cartViewModel.removeAllItemsFromCart()
        orderStage = .building
        totalsViewModel.resetForNewTransaction()
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeSelectedItemToAddToCart() {
        itemSelectorViewModel.selectedItemPublisher.sink { [weak self] selectedItem in
            self?.cartViewModel.addItemToCart(selectedItem)
        }
        .store(in: &subscriptions)
    }

    func observeCartAddMoreTaps() {
        cartViewModel.addMoreToCartPublisher.sink { [weak self] in
            guard let self else { return }
            orderStage = .building
        }
        .store(in: &subscriptions)
    }

    func observeCartSubmissions() {
        cartViewModel.cartSubmissionPublisher.sink { [weak self] cartItems in
            guard let self else { return }
            orderStage = .finalizing
            startSyncingOrder(cartItems: cartItems)
        }
        .store(in: &subscriptions)
    }

    func observeCartItemsForCollapsedState() {
        cartViewModel.$itemsInCart
            .map { $0.isEmpty }
            .assign(to: &$isCartCollapsed)
    }

    func observePaymentStateForButtonDisabledProperties() {
        totalsViewModel.$paymentState
            .map { paymentState in
                switch paymentState {
                case .processingPayment,
                        .cardPaymentSuccessful:
                    return true
                case .idle,
                        .acceptingCard,
                        .preparingReader:
                    return false
                }
            }
            .assign(to: &$isAddMoreDisabled)

        totalsViewModel.$paymentState
            .map { paymentState in
                switch paymentState {
                case .processingPayment:
                    return true
                case .idle,
                        .acceptingCard,
                        .preparingReader,
                        .cardPaymentSuccessful:
                    return false
                }
            }
            .assign(to: &$isExitPOSDisabled)
    }
}

private extension PointOfSaleDashboardViewModel {
    enum OrderSyncError: Error {
        case selfDeallocated
    }
}
