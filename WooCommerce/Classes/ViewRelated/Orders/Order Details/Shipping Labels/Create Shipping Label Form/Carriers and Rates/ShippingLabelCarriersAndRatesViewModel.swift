import UIKit
import SwiftUI
import Yosemite

final class ShippingLabelCarriersAndRatesViewModel: ObservableObject {

    private let order: Order
    private let originAddress: ShippingLabelAddress
    private let destinationAddress: ShippingLabelAddress
    private let packages: [ShippingLabelPackageSelected]
    private let stores: StoresManager

    /// The rows observed by the main view `ShippingLabelCarriersAndRates`
    ///
    @Published private(set) var rows: [ShippingLabelCarrierRow] = []

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
private extension ShippingLabelCarriersAndRatesViewModel {

    func syncCarriersAndRates() {
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
            case .failure(let _):
                self?.rows = []
            }
        }
        stores.dispatch(action)
    }
}
