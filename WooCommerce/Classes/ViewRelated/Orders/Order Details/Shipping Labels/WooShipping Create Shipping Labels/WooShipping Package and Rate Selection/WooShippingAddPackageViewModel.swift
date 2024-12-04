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
    @Published private(set) var storeOptions: ShippingLabelStoreOptions?

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
    private var allPredefinedOptions: [WooShippingCarrierPredefinedOptions] = []
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
        self.storeOptions = packagesResult.storeOptions

        self.allPredefinedOptions = packagesResult.allPredefinedOptions

        starredCarriersPackages = Set(predefinedSavedPackages.map { $0.id })

        if selectedCarriersTabIndex == nil {
            self.selectedCarriersTabIndex = carrierPackages.isEmpty ? nil : 0
        }
    }

    private func transformSavedPackages(_ response: WooShippingCreatePackageResponse) {
        guard let storeOptions = self.storeOptions else {
            return
        }

        // helper function for creating jointIDs for easier checking if package should be used or not
        func jointID(carrierID: String, packageID: String) -> String {
            return "\(carrierID)-\(packageID)"
        }

        var jointIDs: [String] = []
        for option in response.predefinedOptions {
            for packageID in option.predefinedPackageIDs {
                jointIDs.append(jointID(carrierID: option.id, packageID: packageID))
            }
        }

        var allPredefinedSaved: [any WooShippingPackageDataRepresentable] = []

        // use predefined saved packages from list of all packages
        // since the response gives us IDs we need to get them manually from the list
        for carrier in self.allPredefinedOptions {
            let carrierID = carrier.carrierID
            for option in carrier.predefinedOptions {
                for package in option.predefinedPackages {
                    if jointIDs.contains(jointID(carrierID: carrierID, packageID: package.id)) {
                        allPredefinedSaved.append(package.toPackageData(storeOptions: storeOptions,
                                                                        groupTitle: option.title,
                                                                        sourceID: option.providerID))
                    }
                }
            }
        }

        self.predefinedSavedPackages = allPredefinedSaved

        self.customSavedPackages = response.customPackages.map {
            return $0.toPackageData(storeOptions: storeOptions)
        }
    }

    // star/unstar packages
    @MainActor
    func starUnstarPackage(_ packageID: String, carrierID: String) {
        if starredCarriersPackages.contains(packageID) {
            _ = withAnimation(starAnimation) {
                starredCarriersPackages.remove(packageID)
            }
            // TODO: call delete action when it is ready
        }
        else {
            _ = withAnimation(starAnimation) {
                starredCarriersPackages.insert(packageID)
            }

            let predefined = WooShippingPredefinedSavedOption(id: carrierID, predefinedPackageIDs: [packageID])
            let createAction = WooShippingAction.createPackage(siteID: siteID, customPackage: nil, predefinedOption: predefined) { result in
                switch result {
                case .success(let response):
                    self.transformSavedPackages(response)
                case .failure(let error):
                    // TODO: should we undo the starring of the package if request fails?
                    break
                }
            }

            ServiceLocator.stores.dispatch(createAction)
        }
    }

    // delete saved packages
    func removeSavedPackage(_ packageToRemove: WooShippingPackageDataRepresentable) async -> Error? {
        // TODO: rewrite to directly use actions
        // delete the package locally and on backend
        customSavedPackages.removeAll { package in package.id == packageToRemove.id }
        predefinedSavedPackages.removeAll { package in package.id == packageToRemove.id }
        starredCarriersPackages.remove(packageToRemove.id)

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
    func toPackageData(storeOptions: ShippingLabelStoreOptions, groupTitle: String, sourceID: String) -> WooShippingPackageData {
        return WooShippingPackageData(id: id,
                                      name: name,
                                      length: String(getLength()),
                                      width: String(getWidth()),
                                      height: String(getHeight()),
                                      dimensionsUnit: storeOptions.dimensionUnit,
                                      weight: String(boxWeight),
                                      weightUnit: storeOptions.weightUnit,
                                      source: .predefined(sourceTitle: groupTitle, sourceID: sourceID),
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
                                      source: .predefined(sourceTitle: groupTitle, sourceID: providerID),
                                      packageType: self.package.isLetter ? "envelope" : "box")
    }
}

extension WooShippingCarrierPredefinedOptions {
    func toCarrierPackages(storeOptions: ShippingLabelStoreOptions) -> WooShippingCarrierPackages? {
        guard let shippingCarrier = WooShippingCarrier(rawValue: carrierID) else { return nil }

        let packageGroups = predefinedOptions.compactMap { predefinedOption in
            let packages = predefinedOption.predefinedPackages.map { package in
                return package.toPackageData(storeOptions: storeOptions, groupTitle: predefinedOption.title, sourceID: predefinedOption.providerID)
            }
            let group = WooPackageGroup(name: predefinedOption.title, packages: packages)
            return group
        }
        let carrierPackages = WooShippingCarrierPackages(carrier: shippingCarrier, packageGroups: packageGroups)
        return carrierPackages
    }
}
