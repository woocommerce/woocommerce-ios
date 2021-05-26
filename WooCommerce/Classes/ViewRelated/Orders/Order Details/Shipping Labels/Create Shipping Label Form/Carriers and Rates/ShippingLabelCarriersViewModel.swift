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

    @Published private var selectedRate: ShippingLabelCarrierRate?
    @Published private var selectedSignatureRate: ShippingLabelCarrierRate?
    @Published private var selectedAdultSignatureRate: ShippingLabelCarrierRate?

    /// The rows view models observed by the main view `ShippingLabelCarriers`
    ///
    @Published private(set) var rows: [ShippingLabelCarrierRowViewModel] = []

    /// View models of the ghost rows used during the loading process.
    ///
    var ghostRows: [ShippingLabelCarrierRowViewModel] {
        return Array(0..<3).map { _ in
            ShippingLabelCarrierRowViewModel(rate: sampleGhostRate()) { (_, _, _) in }
        }
    }

    init(order: Order,
         originAddress: ShippingLabelAddress,
         destinationAddress: ShippingLabelAddress,
         packages: [ShippingLabelPackageSelected],
         selectedRate: ShippingLabelCarrierRate? = nil,
         selectedSignatureRate: ShippingLabelCarrierRate? = nil,
         selectedAdultSignatureRate: ShippingLabelCarrierRate? = nil,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.originAddress = originAddress
        self.destinationAddress = destinationAddress
        self.packages = packages
        self.selectedRate = selectedRate
        self.selectedSignatureRate = selectedSignatureRate
        self.selectedAdultSignatureRate = selectedAdultSignatureRate
        self.stores = stores
        syncCarriersAndRates()
    }

    func generateRows(response: ShippingLabelCarriersAndRates) {
        self.rows = response.defaultRates.map { rate in
            let signature = response.signatureRequired.first { rate.title == $0.title }
            let adultSignature = response.adultSignatureRequired.first { rate.title == $0.title }

            return ShippingLabelCarrierRowViewModel(selected: rate.title == selectedRate?.title,
                                                    signatureSelected: selectedSignatureRate?.title == signature?.title && signature != nil,
                                                    adultSignatureSelected: selectedAdultSignatureRate?.title == adultSignature?.title && adultSignature != nil,
                                                    rate: rate,
                                                    signatureRate: signature,
                                                    adultSignatureRate: adultSignature) { [weak self] (rate, signature, adultSignature) in
                self?.selectedRate = rate
                self?.selectedSignatureRate = signature
                self?.selectedAdultSignatureRate = adultSignature
                self?.generateRows(response: response)
            }
        }
    }

    /// Return true if the done button should be enabled
    ///
    func isDoneButtonEnabled() -> Bool {
        return selectedRate != nil
    }

    /// Return the selected rates
    ///
    func getSelectedRates() -> (selectedRate: ShippingLabelCarrierRate?,
                                selectedSignatureRate: ShippingLabelCarrierRate?,
                                selectedAdultSignatureRate: ShippingLabelCarrierRate?) {
        return (selectedRate: selectedRate,
                selectedSignatureRate: selectedSignatureRate,
                selectedAdultSignatureRate: selectedAdultSignatureRate)
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
                self.generateRows(response: response)
                self.syncStatus = .success
            case .failure:
                self.rows = []
                self.syncStatus = .error
            }
        }
        stores.dispatch(action)
    }
}

// MARK: - Utils {
private extension ShippingLabelCarriersViewModel {
    private func sampleGhostRate() -> ShippingLabelCarrierRate {
        return ShippingLabelCarrierRate(title: "USPS - Parcel Select Mail",
                                        insurance: 0,
                                        retailRate: 40.060000000000002,
                                        rate: 40.060000000000002,
                                        rateID: "rate_a8a29d5f34984722942f466c30ea27ef",
                                        serviceID: "ParcelSelect",
                                        carrierID: "usps",
                                        shipmentID: "shp_e0e3c2f4606c4b198d0cbd6294baed56",
                                        hasTracking: true,
                                        isSelected: false,
                                        isPickupFree: true,
                                        deliveryDays: 2,
                                        deliveryDateGuaranteed: false)
    }
}
