import Foundation
import SwiftUI
import Combine
import Yosemite

final class WooShippingAddPackageViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager

    init(siteID: Int64 = ServiceLocator.stores.sessionManager.defaultStoreID ?? 0,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
        self.savedPackagesViewModel = WooSavedPackagesSelectionViewModel()
    }

    @Published private(set) var isLoadingPackages: Bool = false

    @Published private(set) var savedPackagesViewModel: WooSavedPackagesSelectionViewModel

    @Published private(set) var carrierPackages: [WooShippingCarrierPackages] = []

    func loadPackages() {
        guard !isLoadingPackages else { return }

        isLoadingPackages = true

        let loadPackagesAction = WooShippingAction.loadPackages(siteID: siteID) { result in
            switch result {
            case .success(let packagesResult):
                self.transformLoadedPackages(packagesResult)
            case .failure:
                break
            }
            self.isLoadingPackages = false
        }

        ServiceLocator.stores.dispatch(loadPackagesAction)
    }

    // transform packages
    private func transformLoadedPackages(_ packagesResult: WooShippingPackagesResponse) {
        let customSavedPackages = packagesResult.customPackages.map {
            return $0.toPackageData(storeOptions: packagesResult.storeOptions)
        }
        let predefinedSavedPackages = packagesResult.savedPredefinedPackages.map {
            return $0.toPackageData(storeOptions: packagesResult.storeOptions)
        }
        savedPackagesViewModel.updatePackages(customSavedPackages: customSavedPackages, predefinedSavedPackages: predefinedSavedPackages)
    }

    // star/unstar packages
    // delete saved packages
}

extension WooShippingCustomPackage {
    func toPackageData(storeOptions: ShippingLabelStoreOptions) -> WooShippingPackageData {
        return WooShippingPackageData(id: id,
                                      name: name,
                                      length: String(getLength()),
                                      width: String(getWidth()),
                                      height: String(getHeight()),
                                      dimensionsUnit: storeOptions.dimensionUnit,
                                      weight: String(boxWeight),
                                      weightUnit: storeOptions.weightUnit,
                                      source: .custom, packageType: rawType)
    }
}

extension WooShippingSavedPredefinedPackage {
    func toPackageData(storeOptions: ShippingLabelStoreOptions) -> WooShippingPackageData {
        return WooShippingPackageData(id: id,
                                      name: self.package.name,
                                      length: String(self.package.getLength()),
                                      width: String(self.package.getWidth()),
                                      height: String(self.package.getHeight()),
                                      dimensionsUnit: storeOptions.dimensionUnit,
                                      weight: self.package.boxWeight,
                                      weightUnit: storeOptions.weightUnit,
                                      source: .predefined(groupTitle),
                                      packageType: self.package.isLetter ? "envelope" : "box")
    }
}
