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
    }

    @Published private(set) var isLoadingPackages: Bool = false

    // MARK: - saved

    @Published var selectedSavedPackageId: String? = nil  // Track the selected package index
    @Published private(set) var customSavedPackages: [any WooShippingPackageDataRepresentable] = []
    @Published private(set) var predefinedSavedPackages: [any WooShippingPackageDataRepresentable] = []
    var hasSavedPackages: Bool {
        return customSavedPackages.isNotEmpty || predefinedSavedPackages.isNotEmpty
    }

    var selectedSavedPackage: WooShippingPackageDataRepresentable? {
        guard let selectedSavedPackageId else { return nil }

        let packages = customSavedPackages + predefinedSavedPackages

        for packageItem in packages {
            if selectedSavedPackageId == packageItem.id {
                return packageItem
            }
        }

        return nil
    }

    // MARK: - carrier

    @Published private(set) var carrierPackages: [WooShippingCarrierPackages] = []

    // MARK: - loading

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
        self.customSavedPackages = customSavedPackages
        self.predefinedSavedPackages = predefinedSavedPackages
    }

    // star/unstar packages

    // delete saved packages
    func removeSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error? {
        // TODO: rewrite to directly use actions
        // delete the package locally and on backend
        customSavedPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedSavedPackages.removeAll { package in package.id == packageToRemove.id }

        if self.selectedSavedPackageId == packageToRemove.id {
            self.selectedSavedPackageId = nil
        }

        return nil
    }
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
