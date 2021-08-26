import Yosemite

/// View model for `ShippingLabelServicePackageList`.
///
final class ShippingLabelServicePackageListViewModel: ObservableObject {

    /// The packages response fetched from API
    ///
    private let packagesResponse: ShippingLabelPackagesResponse?

    // TODO-4744: Get the options not yet enabled on the store
    // These are the already enabled options, used temporarily for creating the initial UI
    var predefinedOptions: [ShippingLabelPredefinedOption] {
        packagesResponse?.predefinedOptions ?? []
    }

    @Published private(set) var selectedPackage: ShippingLabelPredefinedPackage?

    var dimensionUnit: String {
        packagesResponse?.storeOptions.dimensionUnit ?? ""
    }

    init(packagesResponse: ShippingLabelPackagesResponse?) {
        self.packagesResponse = packagesResponse
    }
}

// MARK: - Helper Methods
extension ShippingLabelServicePackageListViewModel {
    func didSelectPackage(_ id: String) {
        for option in predefinedOptions {
            for predefinedPackage in option.predefinedPackages {
                if predefinedPackage.id == id {
                    selectedPackage = predefinedPackage
                    return
                }
            }
        }
    }
}
