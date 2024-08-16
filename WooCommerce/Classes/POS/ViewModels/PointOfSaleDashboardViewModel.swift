import SwiftUI
import protocol Yosemite.POSItem
import class WooFoundation.CurrencySettings
import Combine
import enum Yosemite.OrderStatusEnum
import struct Yosemite.POSCartItem
import struct Yosemite.Order

final class PointOfSaleDashboardViewModel: ObservableObject {
    let cartViewModel: any CartViewModelProtocol
    let totalsViewModel: any TotalsViewModelProtocol
    let itemListViewModel: any ItemListViewModelProtocol

    let cardReaderConnectionViewModel: CardReaderConnectionViewModel

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false
    /// This boolean is used to determine if the whole totals/payments view is occupying the full screen (cart is not showed)
    @Published var isTotalsViewFullScreen: Bool = false
    @Published var isInitialLoading: Bool = false
    @Published var isError: Bool = false
    @Published var isEmpty: Bool = false
    @Published var showExitPOSModal: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init(cardPresentPaymentService: CardPresentPaymentFacade,
         totalsViewModel: any TotalsViewModelProtocol,
         cartViewModel: any CartViewModelProtocol,
         itemListViewModel: any ItemListViewModelProtocol) {
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)
        self.itemListViewModel = itemListViewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel

        observeOrderStage()
        observeSelectedItemToAddToCart()
        observeCartSubmission()
        observeCartAddMoreAction()
        observeCartItemsToCheckIfCartIsEmpty()
        observePaymentStateForButtonDisabledProperties()
        observeItemListState()
    }

    func startNewOrder() {
        // clear cart
        cartViewModel.removeAllItemsFromCart()
        orderStage = .building
        totalsViewModel.startNewOrder()
    }

    private func cartSubmitted(cartItems: [CartItem]) {
        totalsViewModel.checkOutTapped(with: cartItems, allItems: itemListViewModel.items)
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

    func observeCartSubmission() {
        cartViewModel.cartSubmissionPublisher
            .sink { [weak self] cartItems in
                guard let self else { return }
                self.orderStage = .finalizing
                self.cartSubmitted(cartItems: cartItems)
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
        cartViewModel.itemsInCartPublisher
            .filter { $0.isEmpty }
            .sink { [weak self] _ in
                self?.orderStage = .building
            }
            .store(in: &cancellables)
    }

    func observePaymentStateForButtonDisabledProperties() {
        Publishers.CombineLatest(totalsViewModel.paymentStatePublisher, totalsViewModel.orderStatePublisher)
            .map { paymentState, orderState in
                switch paymentState {
                case .processingPayment,
                        .paymentError,
                        .cardPaymentSuccessful,
                        .validatingOrder,
                        .validatingOrderError,
                        .preparingReader:
                    return true
                case .idle, .acceptingCard:
                    return orderState.isSyncing
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
                        .validatingOrder,
                        .validatingOrderError,
                        .preparingReader,
                        .paymentError,
                        .cardPaymentSuccessful:
                    return false
                }
            }
            .assign(to: &$isExitPOSDisabled)

        totalsViewModel.paymentStatePublisher
            .map { paymentState in
                switch paymentState {
                case .processingPayment,
                        .paymentError,
                        .cardPaymentSuccessful:
                    return true
                case .idle,
                        .validatingOrder,
                        .validatingOrderError,
                        .preparingReader,
                        .acceptingCard:
                    return false
                }
            }
            .assign(to: &$isTotalsViewFullScreen)
    }

    private func observeOrderStage() {
        $orderStage.sink { [weak self] stage in
            guard let self else { return }
            cartViewModel.canDeleteItemsFromCart = stage == .building

            if stage == .building {
                totalsViewModel.cancelReaderPreparation()
            }
        }
        .store(in: &cancellables)
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeItemListState() {
        Publishers.CombineLatest(itemListViewModel.statePublisher, itemListViewModel.itemsPublisher)
            .sink { [weak self] state, items in
                guard let self = self else { return }

                self.isInitialLoading = (state == .loading && items.isEmpty)

                switch state {
                case .error:
                    self.isError = true
                case .empty:
                    self.isEmpty = true
                default:
                    self.isError = false
                    self.isEmpty = false
                }
            }
            .store(in: &cancellables)
    }
}

private extension PointOfSaleDashboardViewModel {
    enum OrderSyncError: Error {
        case selfDeallocated
    }
}
