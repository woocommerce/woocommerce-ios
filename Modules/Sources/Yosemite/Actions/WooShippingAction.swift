import Foundation
import Networking

public enum WooShippingAction: Action {
    /// Checks whether an order is eligible for shipping label creation.
    ///
    case checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  onCompletion: (_ isEligible: Bool) -> Void)

    /// Creates a custom package or activated a carrier package with provided package details.
    ///
    case createPackage(siteID: Int64,
                       customPackage: WooShippingCustomPackage? = nil,
                       predefinedOption: WooShippingPredefinedSavedOption? = nil,
                       completion: (Result<WooShippingCreatePackageResponse, PackageCreationError>) -> Void)

    /// Deletes a package or deactivates a carrier package with provided package ID and type.
    ///
    case deletePackage(siteID: Int64,
                       packageID: String,
                       packageType: WooShippingPackageType,
                       completion: (Result<WooShippingCreatePackageResponse, Error>) -> Void)

    /// Fetch list of shipping label rates for the order.
    ///
    /// - Sends back the `packages` parameter value along with the result in the completion handler
    ///
    case loadLabelRates(siteID: Int64,
                        orderID: Int64,
                        originAddress: WooShippingAddress,
                        destinationAddress: WooShippingAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: ([ShippingLabelPackageSelected], Result<[ShippingLabelCarriersAndRates], Error>) -> Void)

    /// Fetch list of packages.
    ///
    case loadPackages(siteID: Int64,
                      completion: (Result<WooShippingPackagesResponse, Error>) -> Void)

    /// Load account settings
    ///
    case loadAccountSettings(siteID: Int64,
                             completion: (Result<WooShippingAccountSettings, Error>) -> Void)

    /// Update account settings
    ///
    case updateAccountSettings(siteID: Int64,
                               settings: ShippingLabelAccountSettings,
                               completion: (Result<Bool, Error>) -> Void)

    /// Purchase a shipping label.
    ///
    case purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: WooShippingAddress,
                               destinationAddress: WooShippingAddress,
                               package: WooShippingPackagePurchase,
                               markOrderComplete: Bool?,
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

    /// Fetch list of origin addresses.
    ///
    case loadOriginAddresses(siteID: Int64,
                             completion: (Result<[WooShippingOriginAddress], Error>) -> Void)

    /// Validate a shipping address.
    ///
    case validateAddress(siteID: Int64,
                         address: WooShippingAddress,
                         completion: (Result<WooShippingAddressValidationSuccess, Error>) -> Void)

    /// Update an origin address.
    ///
    case updateOriginAddress(siteID: Int64,
                             address: WooShippingOriginAddress,
                             isVerified: Bool,
                             completion: (Result<WooShippingOriginAddressUpdate, Error>) -> Void)

    /// Verify destination address of an order.
    ///
    case verifyDestinationAddress(siteID: Int64,
                                  orderID: Int64,
                                  completion: (Result<WooShippingVerifyDestinationAddressSuccess, Error>) -> Void)

    /// Update a destination address of an order.
    ///
    case updateDestinationAddress(siteID: Int64,
                                  orderID: Int64,
                                  address: WooShippingDestinationAddress,
                                  isVerified: Bool,
                                  completion: (Result<WooShippingDestinationAddressUpdate, Error>) -> Void)

    /// Loads label config for a given order
    ///
    case loadConfig(siteID: Int64,
                    orderID: Int64,
                    completion: (Result<WooShippingConfig, Error>) -> Void)

    /// Sync shipments for a given order.
    /// This uses the same endpoint as `loadConfig` but also stores shipments and shipping labels to the storage
    /// and returns them in the completion closure.
    ///
    case syncShipments(siteID: Int64,
                       orderID: Int64,
                       completion: (Result<[WooShippingShipment], Error>) -> Void)

    /// Updates shipments for given order
    ///
    case updateShipment(siteID: Int64,
                        orderID: Int64,
                        shipmentToUpdate: WooShippingUpdateShipment,
                        completion: (Result<WooShippingShipments, Error>) -> Void)

    /// Requests a refund for a shipping label
    ///
    case refundShippingLabel(shippingLabel: ShippingLabel,
                             completion: (Result<ShippingLabel, Error>) -> Void)

    /// Accept UPS TOS for an origin address
    case acceptUPSTermsOfService(siteID: Int64,
                                 originAddress: WooShippingAddress,
                                 completion: (Result<Bool, Error>) -> Void)

    /// Accept FedEx TOS
    case acceptFedExTermsOfService(siteID: Int64,
                                   completion: (Result<Bool, Error>) -> Void)

}
