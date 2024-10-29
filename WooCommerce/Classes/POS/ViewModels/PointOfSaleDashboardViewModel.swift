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

    let posModel: PointOfSaleAggregateModel

    private let connectivityObserver: ConnectivityObserver

    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false
    @Published var isReaderDisconnectionDisabled: Bool = false
    /// This boolean is used to determine if the whole totals/payments view is occupying the full screen (cart is not showed)
    @Published var isTotalsViewFullScreen: Bool = false
    @Published var isInitialLoading: Bool = false
    @Published var isError: Bool = false
    @Published var isEmpty: Bool = false
    @Published var showsConnectivityError: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init(posModel: PointOfSaleAggregateModel,
         totalsViewModel: any TotalsViewModelProtocol,
         cartViewModel: any CartViewModelProtocol,
         itemListViewModel: any ItemListViewModelProtocol,
         connectivityObserver: ConnectivityObserver) {
        self.posModel = posModel
        self.itemListViewModel = itemListViewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
        self.connectivityObserver = connectivityObserver

        observeSelectedItemToAddToCart()
        observePaymentStateForButtonDisabledProperties()
        observeItemListState()
        observeConnectivity()
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

    func observePaymentStateForButtonDisabledProperties() {
        Publishers.CombineLatest(posModel.$paymentState, posModel.$orderState)
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

        posModel.$paymentState
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

        let afterCardTapPaymentStates = posModel.$paymentState
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

    func observeItemListState() {
        Publishers.CombineLatest(itemListViewModel.statePublisher, posModel.$allItems)
            .receive(on: DispatchQueue.main)
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
    func observeConnectivity() {
        connectivityObserver.statusPublisher
            .removeDuplicates()
            .map { connectivityStatus in
                return connectivityStatus == .notReachable
            }
            .assign(to: &$showsConnectivityError)
    }
}
