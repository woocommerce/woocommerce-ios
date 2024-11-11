import Networking

public enum WooShippingAction: Action {
    /// Creates a custom package or activated a carrier package with provided package details.
    ///
    case createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage? = nil,
                       predefinedOption: WooShippingPredefinedOption? = nil,
                       completion: (Result<WooShippingCreatePackageResponse, PackageCreationError>) -> Void)
}
