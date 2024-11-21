import Networking

public enum WooShippingAction: Action {
    /// Creates a custom package or activated a carrier package with provided package details.
    ///
    case createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage? = nil,
                       predefinedOption: WooShippingPredefinedSavedOption? = nil,
                       completion: (Result<WooShippingCreatePackageResponse, PackageCreationError>) -> Void)

    /// Fetch list of shipping label rates for the order.
    ///
    case loadLabelRates(siteID: Int64,
                        orderID: Int64,
                        originAddress: ShippingLabelAddress,
                        destinationAddress: ShippingLabelAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: (Result<[ShippingLabelCarriersAndRates], Error>) -> Void)

    /// Fetch list of packages.
    ///
    case loadPackages(siteID: Int64,
                      completion: (Result<WooShippingPackagesResponse, Error>) -> Void)

    /// Fetch list of packages.
    ///
    case loadAccountSettings(siteID: Int64,
                             completion: (Result<WooShippingAccountSettingsResponse, Error>) -> Void)

    /// Purchase a shipping label.
    ///
    case purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               package: WooShippingPackagePurchase,
                               completion: (Result<ShippingLabel, Error>) -> Void,
                               backendProcessingDelay: TimeInterval = 2.0,
                               pollingDelay: TimeInterval = 1.0,
                               pollingMaximumRetries: Int64 = 3)
}
