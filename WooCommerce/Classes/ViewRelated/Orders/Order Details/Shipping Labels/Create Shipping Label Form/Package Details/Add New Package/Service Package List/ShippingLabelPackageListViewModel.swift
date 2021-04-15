import Foundation
import Yosemite

/// View model for `ShippingLabelPackageList`.
///
final class ShippingLabelPackageListViewModel: ObservableObject {

    private(set) var state: ShippingLabelAddNewPackageViewModel.State
    private(set) var dimensionUnit: String
    private(set) var customPackages: [ShippingLabelCustomPackage]
    private(set) var predefinedOptions: [ShippingLabelPredefinedOption]
    @Published private(set) var selectedCustomPackage: ShippingLabelCustomPackage?
    @Published private(set) var selectedPredefinedPackage: ShippingLabelPredefinedPackage?

    init(state: ShippingLabelAddNewPackageViewModel.State,
         packagesResponse: ShippingLabelPackagesResponse?,
         selectedCustomPackage: ShippingLabelCustomPackage? = nil,
         selectedPredefinedPackage: ShippingLabelPredefinedPackage? = nil) {
        self.state = state
        self.dimensionUnit = packagesResponse?.storeOptions.dimensionUnit ?? ""
        self.customPackages = packagesResponse?.customPackages ?? []
        self.predefinedOptions = packagesResponse?.predefinedOptions ?? []
        didSelectCustomPackage(selectedCustomPackage)
        didSelectPredefinedPackage(selectedPredefinedPackage)
    }

    func didSelectCustomPackage(_ customPackage: ShippingLabelCustomPackage?) {
        guard customPackage != nil else { return }
        selectedPredefinedPackage = nil
        selectedCustomPackage = customPackage
    }

    func didSelectPredefinedPackage(_ predefinedPackage: ShippingLabelPredefinedPackage?) {
        guard predefinedPackage != nil else { return }
        selectedCustomPackage = nil
        selectedPredefinedPackage = predefinedPackage
    }
}
