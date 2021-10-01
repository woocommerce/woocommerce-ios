import UIKit
import SwiftUI
import Yosemite

final class ShippingLabelCarriersViewModel: ObservableObject {

    private(set) var order: Order
    private let originAddress: ShippingLabelAddress
    private let destinationAddress: ShippingLabelAddress
    private let packages: [ShippingLabelPackageSelected]
    private let currencySettings: CurrencySettings
    private let stores: StoresManager
    var shouldDisplayTopBanner: Bool {
        guard let shippingTotal = Double(order.shippingTotal) else {
            return false
        }
        return shippingTotal > 0
    }

    /// We use the first `shipping_line` and we use directly the property `method_title` which is the the same behaviour of the web client.
    /// We use this value in the top banner of the view.
    ///
    var shippingMethod: String {
        order.shippingLines.first?.methodTitle.strippedHTML ?? ""
    }

    /// We use the first `shipping_line` and we use directly the property `method_title` which is the the same behaviour of the web client.
    /// We use this value in the top banner of the view.
    ///
    var shippingCost: String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        return currencyFormatter.formatAmount(order.shippingTotal) ?? ""
    }

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
         currencySettings: CurrencySettings = ServiceLocator.currencySettings,
         stores: StoresManager = ServiceLocator.stores) {
        self.order = order
        self.originAddress = originAddress
        self.destinationAddress = destinationAddress
        self.packages = packages
        self.selectedRate = selectedRate
        self.selectedSignatureRate = selectedSignatureRate
        self.selectedAdultSignatureRate = selectedAdultSignatureRate
        self.currencySettings = currencySettings
        self.stores = stores
        syncCarriersAndRates()
    }

    func generateRows(response: [ShippingLabelCarriersAndRates]) {
        var tempRows: [ShippingLabelCarrierRowViewModel] = []
        for resp in response {
            tempRows += resp.defaultRates.map { rate in
                let signature = resp.signatureRequired.first { rate.title == $0.title }
                let adultSignature = resp.adultSignatureRequired.first { rate.title == $0.title }

                return ShippingLabelCarrierRowViewModel(selected: rate.title == selectedRate?.title,
                                                        signatureSelected: selectedSignatureRate?.title == signature?.title && signature != nil,
                                                        adultSignatureSelected: selectedAdultSignatureRate?.title == adultSignature?.title
                                                        && adultSignature != nil,
                                                        rate: rate,
                                                        signatureRate: signature,
                                                        adultSignatureRate: adultSignature,
                                                        currencySettings: currencySettings) { [weak self] (rate, signature, adultSignature) in
                    self?.selectedRate = rate
                    self?.selectedSignatureRate = signature
                    self?.selectedAdultSignatureRate = adultSignature
                    self?.generateRows(response: response)
                }
            }
        }
        rows = tempRows
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
                if self.rows.isEmpty {
                    self.syncStatus = .error
                }
                else {
                    self.syncStatus = .success
                }
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
                                        insurance: "0",
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
