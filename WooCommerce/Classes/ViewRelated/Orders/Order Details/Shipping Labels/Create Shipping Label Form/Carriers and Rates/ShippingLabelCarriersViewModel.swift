import UIKit
import SwiftUI
import Yosemite

final class ShippingLabelCarriersViewModel: ObservableObject {

    private let order: Order
    private let originAddress: ShippingLabelAddress
    private let destinationAddress: ShippingLabelAddress
    private let packages: [ShippingLabelPackageSelected]
    private let stores: StoresManager

    enum SyncStatus {
        case loading
        case success
        case error
        case none
    }

    @Published private(set) var syncStatus: SyncStatus = .none

    /// The rows view models observed by the main view `ShippingLabelCarriers`
    ///
    @Published private(set) var rows: [ShippingLabelCarrierRowViewModel] = []

    /// View models of the ghost rows used during the loading process.
    ///
    var ghostRows: [ShippingLabelCarrierRowViewModel] {
        
        return []
//        return Array(0..<3).map { _ in
//            ShippingLabelCarrierRowViewModel(selected: false,
//                                             title: "Ghost title",
//                                             subtitle: "Ghost subtitle",
//                                             price: "Ghost price",
//                                             carrier: "ups")
//        }
    }

    init(order: Order,
         originAddress: ShippingLabelAddress,
         destinationAddress: ShippingLabelAddress,
         packages: [ShippingLabelPackageSelected],
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.originAddress = originAddress
        self.destinationAddress = destinationAddress
        self.packages = packages
        self.stores = stores
        syncCarriersAndRates()
    }
}

// MARK: - API Requests
private extension ShippingLabelCarriersViewModel {

    func syncCarriersAndRates() {
        syncStatus = .loading
        let action = ShippingLabelAction.loadCarriersAndRates(siteID: order.siteID,
                                                              orderID: order.orderID,
                                                              originAddress: originAddress,
                                                              destinationAddress: destinationAddress,
                                                              packages: packages) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                self.rows = response.defaultRates.map { rate in
                    ShippingLabelCarrierRowViewModel(selected: false,
                                                     rate: rate)
                }
                self.syncStatus = .success
            case .failure:
                self.rows = []
                self.syncStatus = .error
            }
        }
        stores.dispatch(action)
    }
}
