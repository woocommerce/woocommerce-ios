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
    private let connectivityObserver: ConnectivityObserver

    enum OrderStage {
        case building
        case finalizing
    }

    @Published private(set) var orderStage: OrderStage = .building

    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false
    @Published var isReaderDisconnectionDisabled: Bool = false
    /// This boolean is used to determine if the whole totals/payments view is occupying the full screen (cart is not showed)
    @Published var isTotalsViewFullScreen: Bool = false
    @Published var isInitialLoading: Bool = false
    @Published var isError: Bool = false
    @Published var isEmpty: Bool = false
    @Published var showExitPOSModal: Bool = false
    @Published var showSupport: Bool = false
    @Published var showsConnectivityError: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init(cardPresentPaymentService: CardPresentPaymentFacade,
         totalsViewModel: any TotalsViewModelProtocol,
         cartViewModel: any CartViewModelProtocol,
         itemListViewModel: any ItemListViewModelProtocol,
         connectivityObserver: ConnectivityObserver) {
        self.cardReaderConnectionViewModel = CardReaderConnectionViewModel(cardPresentPayment: cardPresentPaymentService)
        self.itemListViewModel = itemListViewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
        self.connectivityObserver = connectivityObserver

        observeOrderStage()
        observeSelectedItemToAddToCart()
        observeCartSubmission()
        observeCartAddMoreAction()
        observeCartItemsToCheckIfCartIsEmpty()
        observePaymentStateForButtonDisabledProperties()
        observeItemListState()
        observeTotalsStartNewOrderAction()
        observeConnectivity()
    }

    private func startNewOrder() {
        // clear cart
        cartViewModel.removeAllItemsFromCart()
        orderStage = .building
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
                        .preparingReader:
                    return true
                case .idle, .validatingOrderError, .acceptingCard:
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

        let afterCardTapPaymentStates = totalsViewModel.paymentStatePublisher
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
            .share()

        afterCardTapPaymentStates
            .assign(to: &$isTotalsViewFullScreen)

        afterCardTapPaymentStates
            .assign(to: &$isReaderDisconnectionDisabled)

    }

    private func observeOrderStage() {
        $orderStage
            .removeDuplicates()
            .sink { [weak self] stage in
            guard let self else { return }
            cartViewModel.canDeleteItemsFromCart = stage == .building

            switch stage {
            case .building:
                totalsViewModel.stopShowingTotalsView()
            case .finalizing:
                totalsViewModel.startShowingTotalsView()
            }
        }
        .store(in: &cancellables)
    }

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

    func observeTotalsStartNewOrderAction() {
        totalsViewModel.startNewOrderActionPublisher
            .sink { [weak self] in
                guard let self else { return }
                self.startNewOrder()
            }
            .store(in: &cancellables)
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeConnectivity() {
        connectivityObserver.statusPublisher
            .removeDuplicates()
            .map { connectivityStatus in
                return connectivityStatus == .notReachable
            }
            .assign(to: &$showsConnectivityError)
    }
}
