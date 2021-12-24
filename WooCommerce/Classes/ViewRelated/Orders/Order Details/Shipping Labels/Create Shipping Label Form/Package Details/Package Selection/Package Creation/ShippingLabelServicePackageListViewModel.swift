import Yosemite

/// View model for `ShippingLabelServicePackageList`.
///
final class ShippingLabelServicePackageListViewModel: ObservableObject {

    /// The packages response fetched from API
    ///
    @Published private var packagesResponse: ShippingLabelPackagesResponse?

    /// Service packages not yet activated on the store, organized by shipping provider
    ///
    var predefinedOptions: [ShippingLabelPredefinedOption] {
        packagesResponse?.unactivatedPredefinedOptions ?? []
    }

    @Published var selectedPackage: ShippingLabelPredefinedPackage?

    var dimensionUnit: String {
        packagesResponse?.storeOptions.dimensionUnit ?? ""
    }

    var shouldShowEmptyState: Bool {
        predefinedOptions.isEmpty
    }

    init(packagesResponse: ShippingLabelPackagesResponse?) {
        self.packagesResponse = packagesResponse
    }
}
