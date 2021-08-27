import Yosemite

/// View model for `ShippingLabelServicePackageList`.
///
final class ShippingLabelServicePackageListViewModel: ObservableObject {

    /// The packages response fetched from API
    ///
    @Published var packagesResponse: ShippingLabelPackagesResponse?

    // TODO-4744: Get the options not yet enabled on the store
    // These are the already enabled options, used temporarily for creating the initial UI
    var predefinedOptions: [ShippingLabelPredefinedOption] {
        packagesResponse?.predefinedOptions ?? []
    }

    @Published var selectedPackage: ShippingLabelPredefinedPackage?

    var dimensionUnit: String {
        packagesResponse?.storeOptions.dimensionUnit ?? ""
    }
}
