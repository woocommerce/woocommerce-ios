import Foundation
import Networking

import XCTest

/// Mock for `ShippingLabelRemote`.
///
final class MockShippingLabelRemote {
    private struct LoadAllResultKey: Hashable {
        let siteID: Int64
        let orderID: Int64
    }

    private struct PrintResultKey: Hashable {
        let siteID: Int64
        let shippingLabelIDs: [Int64]
        let paperSize: String
    }

    private struct RefundResultKey: Hashable {
        let siteID: Int64
        let orderID: Int64
        let shippingLabelID: Int64
    }

    private struct AddressValidationResultKey: Hashable {
        let siteID: Int64
    }

    private struct PackagesDetailsResultKey: Hashable {
        let siteID: Int64
    }

    private struct CreatePackageResultKey: Hashable {
        let siteID: Int64
    }

    private struct LoadCarriersAndRatesKey: Hashable {
        let siteID: Int64
    }

    private struct LoadAccountSettingsResultKey: Hashable {
        let siteID: Int64
    }

    private struct UpdateAccountSettingsResultKey: Hashable {
        let siteID: Int64
    }

    private struct CreationEligibilityResultKey: Hashable {
        let siteID: Int64
        let orderID: Int64
        let canCreatePaymentMethod: Bool
        let canCreateCustomsForm: Bool
        let canCreatePackage: Bool
    }

    private struct PurchaseShippingLabelResultKey: Hashable {
        let siteID: Int64
    }

    private struct CheckLabelStatusResultKey: Hashable {
        let siteID: Int64
    }

    /// The results to return based on the given arguments in `loadShippingLabels`
    private var loadAllResults = [LoadAllResultKey: Result<OrderShippingLabelListResponse, Error>]()

    /// The results to return based on the given arguments in `printShippingLabel`
    private var printResults = [PrintResultKey: Result<ShippingLabelPrintData, Error>]()

    /// The results to return based on the given arguments in `refundShippingLabel`
    private var refundResults = [RefundResultKey: Result<ShippingLabelRefund, Error>]()

    /// The results to return based on the given arguments in `addressValidation`
    private var addressValidationResults = [AddressValidationResultKey: Result<ShippingLabelAddressValidationSuccess, Error>]()

    /// The results to return based on the given arguments in `packagesDetails`
    private var packagesDetailsResults = [PackagesDetailsResultKey: Result<ShippingLabelPackagesResponse, Error>]()

    /// The results to return based on the given arguments in `createPackage`
    private var createPackageResults = [CreatePackageResultKey: Result<Bool, Error>]()

    /// The results to return based on the given arguments in `loadCarriersAndRates`
    private var loadCarriersAndRatesResults = [LoadCarriersAndRatesKey: Result<[ShippingLabelCarriersAndRates], Error>]()

    /// The results to return based on the given arguments in `loadShippingLabelAccountSettings`
    private var loadAccountSettings = [LoadAccountSettingsResultKey: Result<ShippingLabelAccountSettings, Error>]()

    /// The results to return based on the given arguments in `updateShippingLabelAccountSettings`
    private var updateAccountSettings = [UpdateAccountSettingsResultKey: Result<Bool, Error>]()

    /// The results to return based on the given arguments in `checkCreationEligibility`
    private var creationEligibilityResults = [CreationEligibilityResultKey: Result<ShippingLabelCreationEligibilityResponse, Error>]()

    /// The results to return based on the given arguments in `purchaseShippingLabel`
    private var purchaseShippingLabelResults = [PurchaseShippingLabelResultKey: Result<[ShippingLabelPurchase], Error>]()

    /// The results to return based on the given arguments in `checkLabelStatus`
    private var checkLabelStatusResults = [CheckLabelStatusResultKey: Result<[ShippingLabelStatusPollingResponse], Error>]()

    /// Set the value passed to the `completion` block if `loadShippingLabels` is called.
    func whenLoadingShippingLabels(siteID: Int64,
                                   orderID: Int64,
                                   thenReturn result: Result<OrderShippingLabelListResponse, Error>) {
        let key = LoadAllResultKey(siteID: siteID, orderID: orderID)
        loadAllResults[key] = result
    }

    /// Set the value passed to the `completion` block if `printShippingLabel` is called.
    func whenPrintingShippingLabel(siteID: Int64,
                                   shippingLabelIDs: [Int64],
                                   paperSize: String,
                                   thenReturn result: Result<ShippingLabelPrintData, Error>) {
        let key = PrintResultKey(siteID: siteID, shippingLabelIDs: shippingLabelIDs, paperSize: paperSize)
        printResults[key] = result
    }

    /// Set the value passed to the `completion` block if `refundShippingLabel` is called.
    func whenRefundingShippingLabel(siteID: Int64,
                                    orderID: Int64,
                                    shippingLabelID: Int64,
                                    thenReturn result: Result<ShippingLabelRefund, Error>) {
        let key = RefundResultKey(siteID: siteID, orderID: orderID, shippingLabelID: shippingLabelID)
        refundResults[key] = result
    }

    /// Set the value passed to the `completion` block if `addressValidation` is called.
    func whenValidatingAddress(siteID: Int64,
                               thenReturn result: Result<ShippingLabelAddressValidationSuccess, Error>) {
        let key = AddressValidationResultKey(siteID: siteID)
        addressValidationResults[key] = result
    }

    /// Set the value passed to the `completion` block if `packagesDetails` is called.
    func whenPackagesDetails(siteID: Int64,
                             thenReturn result: Result<ShippingLabelPackagesResponse, Error>) {
        let key = PackagesDetailsResultKey(siteID: siteID)
        packagesDetailsResults[key] = result
    }

    /// Set the value passed to the `completion` block if `createPackage` is called.
    func whenCreatePackage(siteID: Int64,
                           thenReturn result: Result<Bool, Error>) {
        let key = CreatePackageResultKey(siteID: siteID)
        createPackageResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadCarriersAndRates` is called.
    func whenLoadCarriersAndRates(siteID: Int64,
                           thenReturn result: Result<[ShippingLabelCarriersAndRates], Error>) {
        let key = LoadCarriersAndRatesKey(siteID: siteID)
        loadCarriersAndRatesResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadShippingLabelAccountSettings` is called.
    func whenLoadShippingLabelAccountSettings(siteID: Int64,
                                       thenReturn result: Result<ShippingLabelAccountSettings, Error>) {
        let key = LoadAccountSettingsResultKey(siteID: siteID)
        loadAccountSettings[key] = result
    }

    /// Set the value passed to the `completion` block if `updateShippingLabelAccountSettings` is called.
    func whenUpdateShippingLabelAccountSettings(siteID: Int64,
                                                settings: ShippingLabelAccountSettings,
                                                thenReturn result: Result<Bool, Error>) {
        let key = UpdateAccountSettingsResultKey(siteID: siteID)
        updateAccountSettings[key] = result
    }

    func whenCheckingCreationEligiblity(siteID: Int64,
                                        orderID: Int64,
                                        canCreatePaymentMethod: Bool,
                                        canCreateCustomsForm: Bool,
                                        canCreatePackage: Bool,
                                        thenReturn result: Result<ShippingLabelCreationEligibilityResponse, Error>) {
        let key = CreationEligibilityResultKey(siteID: siteID,
                                               orderID: orderID,
                                               canCreatePaymentMethod: canCreatePaymentMethod,
                                               canCreateCustomsForm: canCreateCustomsForm,
                                               canCreatePackage: canCreatePackage)
        creationEligibilityResults[key] = result
    }

    /// Set the value passed to the `completion` block if `purchaseShippingLabel` is called.
    func whenPurchaseShippingLabel(siteID: Int64,
                                   orderID: Int64,
                                   originAddress: ShippingLabelAddress,
                                   destinationAddress: ShippingLabelAddress,
                                   packages: [ShippingLabelPackagePurchase],
                                   emailCustomerReceipt: Bool,
                                   thenReturn result: Result<[ShippingLabelPurchase], Error>) {
        let key = PurchaseShippingLabelResultKey(siteID: siteID)
        purchaseShippingLabelResults[key] = result
    }

    /// Set the value passed to the `completion` block if `checkLabelStatus` is called.
    func whenCheckLabelStatus(siteID: Int64,
                              orderID: Int64,
                              labelIDs: [Int64],
                              thenReturn result: Result<[ShippingLabelStatusPollingResponse], Error>) {
        let key = CheckLabelStatusResultKey(siteID: siteID)
        checkLabelStatusResults[key] = result
    }
}

// MARK: - ShippingLabelRemoteProtocol
extension MockShippingLabelRemote: ShippingLabelRemoteProtocol {
    func loadShippingLabels(siteID: Int64, orderID: Int64, completion: @escaping (Result<OrderShippingLabelListResponse, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = LoadAllResultKey(siteID: siteID, orderID: orderID)
            if let result = self.loadAllResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func printShippingLabel(siteID: Int64,
                            shippingLabelIDs: [Int64],
                            paperSize: ShippingLabelPaperSize,
                            completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = PrintResultKey(siteID: siteID, shippingLabelIDs: shippingLabelIDs, paperSize: paperSize.rawValue)
            if let result = self.printResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func refundShippingLabel(siteID: Int64, orderID: Int64, shippingLabelID: Int64, completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = RefundResultKey(siteID: siteID, orderID: orderID, shippingLabelID: shippingLabelID)
            if let result = self.refundResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func addressValidation(siteID: Int64, address: ShippingLabelAddressVerification,
                           completion: @escaping (Result<ShippingLabelAddressValidationSuccess, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = AddressValidationResultKey(siteID: siteID)
            if let result = self.addressValidationResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func packagesDetails(siteID: Int64, completion: @escaping (Result<ShippingLabelPackagesResponse, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = PackagesDetailsResultKey(siteID: siteID)
            if let result = self.packagesDetailsResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func createPackage(siteID: Int64,
                       customPackage: ShippingLabelCustomPackage?,
                       predefinedOption: ShippingLabelPredefinedOption?,
                       completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = CreatePackageResultKey(siteID: siteID)
            if let result = self.createPackageResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func loadCarriersAndRates(siteID: Int64,
                              orderID: Int64,
                              originAddress: ShippingLabelAddress,
                              destinationAddress: ShippingLabelAddress,
                              packages: [ShippingLabelPackageSelected],
                              completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let key = LoadCarriersAndRatesKey(siteID: siteID)

            if let result = self.loadCarriersAndRatesResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func loadShippingLabelAccountSettings(siteID: Int64, completion: @escaping (Result<ShippingLabelAccountSettings, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = LoadAccountSettingsResultKey(siteID: siteID)
            if let result = self.loadAccountSettings[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func updateShippingLabelAccountSettings(siteID: Int64,
                                            settings: ShippingLabelAccountSettings,
                                            completion: @escaping (Result<Bool, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = UpdateAccountSettingsResultKey(siteID: siteID)
            if let result = self.updateAccountSettings[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  canCreatePaymentMethod: Bool,
                                  canCreateCustomsForm: Bool,
                                  canCreatePackage: Bool,
                                  completion: @escaping (Result<ShippingLabelCreationEligibilityResponse, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = CreationEligibilityResultKey(siteID: siteID,
                                                   orderID: orderID,
                                                   canCreatePaymentMethod: canCreatePaymentMethod,
                                                   canCreateCustomsForm: canCreateCustomsForm,
                                                   canCreatePackage: canCreatePackage)
            if let result = self.creationEligibilityResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               packages: [ShippingLabelPackagePurchase],
                               emailCustomerReceipt: Bool,
                               completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = PurchaseShippingLabelResultKey(siteID: siteID)
            if let result = self.purchaseShippingLabelResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func checkLabelStatus(siteID: Int64,
                          orderID: Int64,
                          labelIDs: [Int64],
                          completion: @escaping (Result<[ShippingLabelStatusPollingResponse], Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = CheckLabelStatusResultKey(siteID: siteID)
            if let result = self.checkLabelStatusResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
