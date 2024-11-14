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

    @ObservedObject var posModel: PointOfSaleAggregateModel

    private let connectivityObserver: ConnectivityObserver

    @Published private(set) var isAddMoreDisabled: Bool = false
    @Published var isExitPOSDisabled: Bool = false
    @Published var isReaderDisconnectionDisabled: Bool = false
    /// This boolean is used to determine if the whole totals/payments view is occupying the full screen (cart is not showed)
    @Published var isTotalsViewFullScreen: Bool = false
    @Published var showExitPOSModal: Bool = false
    @Published var showSupport: Bool = false
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
        observeTotalsOrderActions()
        observeConnectivity()
    }

    private func startNewOrder() {
        posModel.startNewCart()
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeSelectedItemToAddToCart() {
        itemListViewModel.selectedItemPublisher
            .sink { [weak self] selectedItem in
                self?.posModel.addToCart(selectedItem)
            }
            .store(in: &cancellables)
    }

    func observePaymentStateForButtonDisabledProperties() {
        Publishers.CombineLatest(totalsViewModel.paymentStatePublisher, posModel.$orderState)
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

    func observeTotalsOrderActions() {
        totalsViewModel.startNewOrderActionPublisher
            .sink { [weak self] in
                guard let self else { return }
                self.startNewOrder()
            }
            .store(in: &cancellables)

        totalsViewModel.editOrderActionPublisher
            .sink { [weak self] in
                guard let self else { return }
                posModel.addMoreToCart()
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
