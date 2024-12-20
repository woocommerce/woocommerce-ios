import Networking

public enum WooShippingAction: Action {
    /// Creates a custom package or activated a carrier package with provided package details.
    ///
    case createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage? = nil,
                       predefinedOption: WooShippingPredefinedSavedOption? = nil,
                       completion: (Result<WooShippingCreatePackageResponse, PackageCreationError>) -> Void)

    /// Deletes a custom package or deactivates a carrier package with provided package ID.
    ///
    case deletePackage(siteID: Int64,
                       packageID: String,
                       completion: (Result<WooShippingCreatePackageResponse, Error>) -> Void)

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
                      completion: (Result<WooShippingPackagesResponse, WooShippingLoadPackagesError>) -> Void)

    /// Fetch list of packages.
    ///
    case loadAccountSettings(siteID: Int64,
                             completion: (Result<WooShippingAccountSettings, Error>) -> Void)

    /// Purchase a shipping label.
    ///
    case purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               package: WooShippingPackagePurchase,
                               backendProcessingDelay: TimeInterval = 2.0,
                               pollingDelay: TimeInterval = 1.0,
                               pollingMaximumRetries: Int64 = 3,
                               completion: (Result<ShippingLabel, Error>) -> Void)

    /// Generates a shipping label document for printing.
    ///
    case printLabel(siteID: Int64,
                    labelIDs: [Int64],
                    paperSize: ShippingLabelPaperSize,
                    completion: (Result<ShippingLabelPrintData, Error>) -> Void)
}
