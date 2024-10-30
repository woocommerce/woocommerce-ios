import SwiftUI
import protocol Yosemite.POSItem
import class WooFoundation.CurrencySettings
import Combine
import enum Yosemite.OrderStatusEnum
import struct Yosemite.POSCartItem
import struct Yosemite.Order

final class PointOfSaleDashboardViewModel: ObservableObject {
    let posModel: PointOfSaleAggregateModel

    private let connectivityObserver: ConnectivityObserver

    @Published var isError: Bool = false
    @Published var isEmpty: Bool = false
    @Published var showsConnectivityError: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    init(posModel: PointOfSaleAggregateModel,
         connectivityObserver: ConnectivityObserver) {
        self.posModel = posModel
        self.connectivityObserver = connectivityObserver

        observeItemListState()
        observeConnectivity()
    }
}

private extension PointOfSaleDashboardViewModel {
    func observeItemListState() {
        posModel.$itemListState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
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
