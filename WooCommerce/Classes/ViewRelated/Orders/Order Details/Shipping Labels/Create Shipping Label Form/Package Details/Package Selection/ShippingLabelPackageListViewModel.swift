import Foundation
import Yosemite

/// View model for `ShippingLabelPackageList` and `ShippingLabelPackageSelection`.
///
final class ShippingLabelPackageListViewModel: ObservableObject {
    @Published private(set) var selectedCustomPackage: ShippingLabelCustomPackage?
    @Published private(set) var selectedPredefinedPackage: ShippingLabelPredefinedPackage?

    var dimensionUnit: String {
        return packagesResponse?.storeOptions.dimensionUnit ?? ""
    }
    var customPackages: [ShippingLabelCustomPackage] {
        return packagesResponse?.customPackages ?? []
    }
    var predefinedOptions: [ShippingLabelPredefinedOption] {
        return packagesResponse?.predefinedOptions ?? []
    }

    /// Returns if the custom packages header should be shown in Package List
    ///
    var showCustomPackagesHeader: Bool {
        return customPackages.count > 0
    }

    /// Whether there are saved custom or predefined packages to select from.
    ///
    var hasCustomOrPredefinedPackages: Bool {
        return customPackages.isNotEmpty || predefinedOptions.isNotEmpty
    }

    lazy var addNewPackageViewModel: ShippingLabelAddNewPackageViewModel = ShippingLabelAddNewPackageViewModel(packagesResponse: packagesResponse)

    /// The packages  response fetched from API
    ///
    private let packagesResponse: ShippingLabelPackagesResponse?

    init(packagesResponse: ShippingLabelPackagesResponse?) {
        self.packagesResponse = packagesResponse
    }
}

// MARK: - Package Selection
extension ShippingLabelPackageListViewModel {
    func didSelectPackage(_ id: String) {
        selectCustomPackage(id)
        selectPredefinedPackage(id)
    }

    // TODO-4599 - Update selection
    func confirmPackageSelection() {}

    private func selectCustomPackage(_ id: String) {
        guard let packagesResponse = packagesResponse else {
            return
        }

        for customPackage in packagesResponse.customPackages {
            if customPackage.title == id {
                selectedCustomPackage = customPackage
                selectedPredefinedPackage = nil
                return
            }
        }
    }

    private func selectPredefinedPackage(_ id: String) {
        guard let packagesResponse = packagesResponse else {
            return
        }

        for option in packagesResponse.predefinedOptions {
            for predefinedPackage in option.predefinedPackages {
                if predefinedPackage.id == id {
                    selectedCustomPackage = nil
                    selectedPredefinedPackage = predefinedPackage
                    return
                }
            }
        }
    }
}
