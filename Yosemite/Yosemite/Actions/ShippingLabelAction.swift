import Networking

public enum ShippingLabelAction: Action {
    /// Syncs shipping labels for a given order.
    ///
    case synchronizeShippingLabels(siteID: Int64, orderID: Int64, completion: (Result<Void, Error>) -> Void)

    /// Generates a shipping label document for printing.
    ///
    case printShippingLabel(siteID: Int64,
                            shippingLabelIDs: [Int64],
                            paperSize: ShippingLabelPaperSize,
                            completion: (Result<ShippingLabelPrintData, Error>) -> Void)

    /// Requests a refund for a shipping label.
    ///
    case refundShippingLabel(shippingLabel: ShippingLabel,
                             completion: (Result<ShippingLabelRefund, Error>) -> Void)

    /// Loads the settings for a shipping label.
    ///
    case loadShippingLabelSettings(shippingLabel: ShippingLabel, completion: (ShippingLabelSettings?) -> Void)

    /// Validate a shipping address.
    ///
    case validateAddress(siteID: Int64,
                         address: ShippingLabelAddressVerification,
                         completion: (Result<ShippingLabelAddressValidationSuccess, Error>) -> Void)

    /// Requests all the details for the packages (custom and predefined).
    ///
    case packagesDetails(siteID: Int64,
                         completion: (Result<ShippingLabelPackagesResponse, Error>) -> Void)

    /// Checks whether an order is eligible for shipping label creation.
    ///
    case checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  canCreatePaymentMethod: Bool,
                                  canCreateCustomsForm: Bool,
                                  canCreatePackage: Bool,
                                  onCompletion: (_ isEligible: Bool) -> Void)

    /// Creates a custom package with provided package details.
    ///
    case createPackage(siteID: Int64,
                       customPackage: ShippingLabelCustomPackage? = nil,
                       predefinedOption: ShippingLabelPredefinedOption? = nil,
                       completion: (Result<Bool, PackageCreationError>) -> Void)

    /// Fetch list of shipping carriers and their rates
    ///
    case loadCarriersAndRates(siteID: Int64,
                              orderID: Int64,
                              originAddress: ShippingLabelAddress,
                              destinationAddress: ShippingLabelAddress,
                              packages: [ShippingLabelPackageSelected],
                              completion: (Result<[ShippingLabelCarriersAndRates], Error>) -> Void)

    /// Loads account-level shipping label settings for a store.
    ///
    case synchronizeShippingLabelAccountSettings(siteID: Int64,
                                                 completion: (Result<ShippingLabelAccountSettings, Error>) -> Void)

    /// Updates account-level shipping label settings for a store.
    ///
    case updateShippingLabelAccountSettings(siteID: Int64,
                                            settings: ShippingLabelAccountSettings,
                                            completion: (Result<Bool, Error>) -> Void)

    /// Purchases a shipping label
    ///
    case purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               packages: [ShippingLabelPackagePurchase],
                               emailCustomerReceipt: Bool,
                               completion: (Result<[ShippingLabel], Error>) -> Void)

    /// Fetches shipping scale data, including package weight
    ///
    case fetchScaleStatus(siteID: Int64,
                        completion: (Result<ShippingScaleStatus, Error>) -> Void)
}
