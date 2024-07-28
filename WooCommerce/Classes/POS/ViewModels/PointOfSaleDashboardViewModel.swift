import SwiftUI
import Combine
import class WooFoundation.CurrencySettings
import class WooFoundation.CurrencyFormatter
import enum Yosemite.OrderStatusEnum
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSOrderServiceProtocol
import protocol Yosemite.POSItem

final class PointOfSaleDashboardViewModel: ObservableObject {
    let cartViewModel: any CartViewModelProtocol
    let totalsViewModel: any TotalsViewModelProtocol
    let itemListViewModel: any ItemListViewModelProtocol

    let cardReaderConnectionViewModel: CardReaderConnectionViewModel

    enum OrderStage {
        case building
        case finalizing
    }

    enum ActiveModal: Identifiable {
        case simpleProducts
        // Add other modals if needed

        var id: String {
            switch self {
            case .simpleProducts:
                return "simpleProducts"
            }
        }
    }

    @Published private(set) var orderStage: OrderStage = .building {
        didSet {
            orderStageSubject.send(orderStage)
        }
    }

    private let orderStageSubject = PassthroughSubject<OrderStage, Never>()

    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false
    @Published var isTotalsViewFullScreen: Bool = false
    @Published var isInitialLoading: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    @Published var activeModal: ActiveModal? = nil

    init(cardPresentPaymentService: CardPresentPaymentFacade,
         itemProvider: POSItemProvider,
         orderService: POSOrderServiceProtocol,
         currencyFormatter: CurrencyFormatter,
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

    func startNewTransaction() {
        // clear cart
        cartViewModel.removeAllItemsFromCart()
        orderStage = .building
        totalsViewModel.startNewTransaction()
    }

    private func startSyncingOrder(cartItems: [CartItem]) {
        totalsViewModel.startSyncingOrder(with: cartItems, allItems: itemListViewModel.items)
    }

    func showModal(_ modal: ActiveModal) {
        activeModal = modal
    }

    func hideModal() {
        activeModal = nil
    }

    func shouldShowModal(_ modal: ActiveModal) -> Bool {
        return activeModal == modal
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
        cartViewModel.itemsInCartPublisher
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
                        .validatingOrder,
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
                        .validatingOrder,
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
                        .validatingOrder,
                        .preparingReader,
                        .acceptingCard:
                    return false
                }
            }
            .assign(to: &$isTotalsViewFullScreen)
    }

    private func observeOrderStage() {
        cartViewModel.bind(to: orderStageSubject.eraseToAnyPublisher())
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeItemListState() {
        Publishers.CombineLatest(itemListViewModel.statePublisher, itemListViewModel.itemsPublisher)
            .map { state, items -> Bool in
                return state == .loading && items.isEmpty
            }
            .assign(to: &$isInitialLoading)
    }
}

private extension PointOfSaleDashboardViewModel {
    enum OrderSyncError: Error {
        case selfDeallocated
    }
}
