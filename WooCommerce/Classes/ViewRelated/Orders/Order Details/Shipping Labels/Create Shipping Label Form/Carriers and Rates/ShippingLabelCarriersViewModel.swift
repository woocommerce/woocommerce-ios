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

    /// The rows observed by the main view `ShippingLabelCarriersAndRates`
    ///
    @Published private(set) var rows: [ShippingLabelCarrierRow] = []

    var ghostRows: [ShippingLabelCarrierRow] {
        var tempRows: [ShippingLabelCarrierRow] = []
        for _ in 0..<3 {
            let row = ShippingLabelCarrierRow(title: "Ghost title",
                                              subtitle: "Ghost subtitle",
                                              price: "Ghost price",
                                              image: nil)
            tempRows.append(row)
        }
        return tempRows
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
            switch result {
            case .success(let response):
                var tempRows: [ShippingLabelCarrierRow] = []
                for rate in response.defaultRates {
                    let row = ShippingLabelCarrierRow(title: rate.title,
                                                     subtitle: "\(rate.deliveryDays) business days",
                                                     price: "\(rate.retailRate)",
                                                     image:
                                                        UIImage(named: "shipping-label-ups-logo")!)
                    tempRows.append(row)
                }
                self?.rows = tempRows
                self?.syncStatus = .success
            case .failure:
                self?.rows = []
                self?.syncStatus = .error
            }
        }
        stores.dispatch(action)
    }
}
