import Foundation
import SwiftUI
import Combine
import Yosemite

final class WooShippingAddPackageViewModel: ObservableObject {
    private let siteID: Int64
    private let stores: StoresManager

    private let starAnimation: Animation = .spring(duration: 0.2)

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
    @Published var selectedCarriersTabIndex: Int? = nil
    @Published var selectedCarriersPackageId: String? = nil
    @Published var starredCarriersPackages: Set<String> = []
    @Published private(set) var carrierTabs: [TopTabItem<EmptyView>] = []
    var selectedCarrierTab: WooShippingCarrierPackages? {
        guard let selectedCarriersTabIndex else { return nil }

        return carrierPackages[selectedCarriersTabIndex]
    }
    var selectedCarriersPackage: WooShippingPackageDataRepresentable? {
        guard let selectedCarriersPackageId else { return nil }

        for carrierTab in carrierPackages {
            for packageGroup in carrierTab.packageGroups {
                for packageItem in packageGroup.packages {
                    if selectedCarriersPackageId == packageItem.id {
                        return packageItem
                    }
                }
            }
        }

        return nil
    }

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
        let carrierPackages: [WooShippingCarrierPackages] = packagesResult.allPredefinedOptions.compactMap {
            return $0.toCarrierPackages(storeOptions: packagesResult.storeOptions)
        }
        let carrierTabs: [TopTabItem<EmptyView>] = carrierPackages.map { carrierTab in
            return TopTabItem(name: carrierTab.carrier.name, icon: carrierTab.carrier.logo, content: {
                EmptyView()
            })
        }

        self.customSavedPackages = customSavedPackages
        self.predefinedSavedPackages = predefinedSavedPackages
        self.carrierPackages = carrierPackages
        self.carrierTabs = carrierTabs
        if selectedCarriersTabIndex == nil {
            self.selectedCarriersTabIndex = carrierPackages.isEmpty ? nil : 0
        }
    }

    // star/unstar packages
    func starUnstarPackage(_ packageID: String) async -> Error? {
        if starredCarriersPackages.contains(packageID) {
            _ = withAnimation(starAnimation) {
                starredCarriersPackages.remove(packageID)
            }
        }
        else {
            _ = withAnimation(starAnimation) {
                starredCarriersPackages.insert(packageID)
            }
        }
        return nil
    }

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
                                      source: .custom,
                                      packageType: rawType)
    }
}

extension WooShippingPredefinedPackage {
    func toPackageData(storeOptions: ShippingLabelStoreOptions, groupTitle: String) -> WooShippingPackageData {
        return WooShippingPackageData(id: id,
                                      name: name,
                                      length: String(getLength()),
                                      width: String(getWidth()),
                                      height: String(getHeight()),
                                      dimensionsUnit: storeOptions.dimensionUnit,
                                      weight: String(boxWeight),
                                      weightUnit: storeOptions.weightUnit,
                                      source: .predefined(groupTitle),
                                      packageType: isLetter ? "envelope" : "box")
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

extension WooShippingCarrierPredefinedOptions {
    func toCarrierPackages(storeOptions: ShippingLabelStoreOptions) -> WooShippingCarrierPackages? {
        guard let shippingCarrier = WooShippingCarrier(rawValue: carrierID) else { return nil }

        let packageGroups = predefinedOptions.compactMap { predefinedOption in
            let packages = predefinedOption.predefinedPackages.map { package in
                return package.toPackageData(storeOptions: storeOptions, groupTitle: predefinedOption.title)
            }
            let group = WooPackageGroup(name: predefinedOption.title, packages: packages)
            return group
        }
        let carrierPackages = WooShippingCarrierPackages(carrier: shippingCarrier, packageGroups: packageGroups)
        return carrierPackages
    }
}
