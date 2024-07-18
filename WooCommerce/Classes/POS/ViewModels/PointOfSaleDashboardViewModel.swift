import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import protocol Yosemite.POSOrderServiceProtocol
import struct Yosemite.POSOrder
import Combine
import enum Yosemite.OrderStatusEnum
import struct Yosemite.POSCartItem
import struct Yosemite.Order

final class PointOfSaleDashboardViewModel: ObservableObject {
    let itemListViewModel: ItemListViewModel
    var cartViewModel: CartViewModel
    let totalsViewModel: AnyTotalsViewModel

    @Published private(set) var isCartCollapsed: Bool = true

    let cardReaderConnectionViewModel: CardReaderConnectionViewModel

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building {
        didSet {
            orderStageSubject.send(orderStage)
        }
    }

    private let orderStageSubject = PassthroughSubject<OrderStage, Never>()

    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false
    /// This boolean is used to determine if the whole totals/payments view is occupying the full screen (cart is not showed)
    @Published var isTotalsViewFullScreen: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init(itemProvider: POSItemProvider,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter,
         totalsViewModel: AnyTotalsViewModel? = nil) {
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)
        self.itemListViewModel = ItemListViewModel(itemProvider: itemProvider)
        self.totalsViewModel = totalsViewModel ?? AnyTotalsViewModel(TotalsViewModel(orderService: orderService,
                                                                                     cardPresentPaymentService: cardPresentPaymentService,
                                                                                     currencyFormatter: currencyFormatter))
        self.cartViewModel = CartViewModel(orderStage: orderStageSubject.eraseToAnyPublisher())

        observeSelectedItemToAddToCart()
        observeCartItemsForCollapsedState()
        observeCartSubmission()
        observeCartAddMoreAction()
        observeCartItemsToCheckIfCartIsEmpty()
        observePaymentStateForButtonDisabledProperties()
    }

    func startNewTransaction() {
        // clear cart
        cartViewModel.removeAllItemsFromCart()
        orderStage = .building
        totalsViewModel.startNewTransaction()
    }

    private func startSyncingOrder(cartItems: [CartItem]) {
        totalsViewModel.startSyncingOrder(with: cartItems, allItems: itemListViewModel.items)
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeSelectedItemToAddToCart() {
        itemListViewModel.selectedItemPublisher
            .sink { [weak self] selectedItem in
                self?.cartViewModel.addItemToCart(selectedItem)
            }
            .store(in: &cancellables)
    }

    func observeCartItemsForCollapsedState() {
        cartViewModel.$itemsInCart
            .map { $0.isEmpty }
            .assign(to: &$isCartCollapsed)
    }

    func observeCartSubmission() {
        cartViewModel.cartSubmissionPublisher
            .sink { [weak self] cartItems in
                guard let self else { return }
                self.orderStage = .finalizing
                self.startSyncingOrder(cartItems: cartItems)
            }
            .store(in: &cancellables)
    }

    func observeCartAddMoreAction() {
        cartViewModel.addMoreToCartActionPublisher
            .sink { [weak self] in
                guard let self else { return }
                self.orderStage = .building
            }
            .store(in: &cancellables)
    }

    func observeCartItemsToCheckIfCartIsEmpty() {
        cartViewModel.$itemsInCart
            .filter { $0.isEmpty }
            .sink { [weak self] _ in
                self?.orderStage = .building
            }
            .store(in: &cancellables)
    }

    func observePaymentStateForButtonDisabledProperties() {
        Publishers.CombineLatest(totalsViewModel.paymentStatePublisher, totalsViewModel.isSyncingOrderPublisher)
            .map { paymentState, isSyncingOrder in
                switch paymentState {
                case .processingPayment,
                        .cardPaymentSuccessful:
                    return true
                case .idle,
                        .acceptingCard,
                        .preparingReader:
                    return isSyncingOrder
                }
            }
            .assign(to: &$isAddMoreDisabled)

        totalsViewModel.paymentStatePublisher
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

        totalsViewModel.paymentStatePublisher
            .map { paymentState in
                switch paymentState {
                case .processingPayment,
                        .cardPaymentSuccessful:
                    return true
                case .idle,
                        .preparingReader,
                        .acceptingCard:
                    return false
                }
            }
            .assign(to: &$isTotalsViewFullScreen)
    }
}

private extension PointOfSaleDashboardViewModel {
    enum OrderSyncError: Error {
        case selfDeallocated
    }
}

// Conform to the protocol needed for unit testing
extension PointOfSaleDashboardViewModel: PointOfSaleDashboardViewModelProtocol {
    func simulateOrderSyncing(cartItems: [CartItem]) {
        startSyncingOrder(cartItems: cartItems)
    }
}
