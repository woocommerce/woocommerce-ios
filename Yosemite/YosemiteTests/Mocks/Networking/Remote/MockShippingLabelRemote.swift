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
        let shippingLabelID: Int64
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

    /// The results to return based on the given arguments in `loadShippingLabels`
    private var loadAllResults = [LoadAllResultKey: Result<OrderShippingLabelListResponse, Error>]()

    /// The results to return based on the given arguments in `printShippingLabel`
    private var printResults = [PrintResultKey: Result<ShippingLabelPrintData, Error>]()

    /// The results to return based on the given arguments in `refundShippingLabel`
    private var refundResults = [RefundResultKey: Result<ShippingLabelRefund, Error>]()

    /// The results to return based on the given arguments in `addressValidation`
    private var addressValidationResults = [AddressValidationResultKey: Result<ShippingLabelAddressValidationResponse, Error>]()

    /// The results to return based on the given arguments in `packagesDetails`
    private var packagesDetailsResults = [PackagesDetailsResultKey: Result<ShippingLabelPackagesResponse, Error>]()

    /// Set the value passed to the `completion` block if `loadShippingLabels` is called.
    func whenLoadingShippingLabels(siteID: Int64,
                                   orderID: Int64,
                                   thenReturn result: Result<OrderShippingLabelListResponse, Error>) {
        let key = LoadAllResultKey(siteID: siteID, orderID: orderID)
        loadAllResults[key] = result
    }

    /// Set the value passed to the `completion` block if `printShippingLabel` is called.
    func whenPrintingShippingLabel(siteID: Int64,
                                   shippingLabelID: Int64,
                                   paperSize: String,
                                   thenReturn result: Result<ShippingLabelPrintData, Error>) {
        let key = PrintResultKey(siteID: siteID, shippingLabelID: shippingLabelID, paperSize: paperSize)
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
                               thenReturn result: Result<ShippingLabelAddressValidationResponse, Error>) {
        let key = AddressValidationResultKey(siteID: siteID)
        addressValidationResults[key] = result
    }

    /// Set the value passed to the `completion` block if `packagesDetails` is called.
    func whenPackagesDetails(siteID: Int64,
                             thenReturn result: Result<ShippingLabelPackagesResponse, Error>) {
        let key = PackagesDetailsResultKey(siteID: siteID)
        packagesDetailsResults[key] = result
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
                            shippingLabelID: Int64,
                            paperSize: ShippingLabelPaperSize,
                            completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = PrintResultKey(siteID: siteID, shippingLabelID: shippingLabelID, paperSize: paperSize.rawValue)
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
                           completion: @escaping (Result<ShippingLabelAddressValidationResponse, Error>) -> Void) {
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
}
