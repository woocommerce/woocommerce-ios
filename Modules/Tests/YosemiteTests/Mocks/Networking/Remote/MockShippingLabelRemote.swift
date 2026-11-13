import Foundation
@testable import Networking
import Synchronization

import XCTest

/// Mock for `ShippingLabelRemote`.
///
final class MockShippingLabelRemote: Sendable {
    private struct State {
        var purchaseShippingLabelCalled = false
        var checkLabelStatusCallsCount = 0
        var loadAllResults = [LoadAllResultKey: Result<([ShippingLabel], ShippingLabelSettings), Error>]()
        var printResults = [PrintResultKey: Result<ShippingLabelPrintData, Error>]()
        var refundResults = [RefundResultKey: Result<ShippingLabelRefund, Error>]()
        var addressValidationResults = [AddressValidationResultKey: Result<ShippingLabelAddressValidationSuccess, Error>]()
        var packagesDetailsResults = [PackagesDetailsResultKey: Result<ShippingLabelPackagesResponse, Error>]()
        var createPackageResults = [CreatePackageResultKey: Result<Bool, Error>]()
        var loadCarriersAndRatesResults = [LoadCarriersAndRatesKey: Result<[ShippingLabelCarriersAndRates], Error>]()
        var loadAccountSettings = [LoadAccountSettingsResultKey: Result<ShippingLabelAccountSettings, Error>]()
        var updateAccountSettings = [UpdateAccountSettingsResultKey: Result<Bool, Error>]()
        var creationEligibilityResults = [CreationEligibilityResultKey: Result<ShippingLabelCreationEligibilityResponse, Error>]()
        var purchaseShippingLabelResults = [PurchaseShippingLabelResultKey: Result<[ShippingLabelPurchase], Error>]()
        var checkLabelStatusResults = [CheckLabelStatusResultKey: Result<[ShippingLabelStatusPollingResponse], Error>]()
    }

    private let state = Mutex(State())

    var purchaseShippingLabelCalled: Bool { state.withLock { $0.purchaseShippingLabelCalled } }
    var checkLabelStatusCallsCount: Int { state.withLock { $0.checkLabelStatusCallsCount } }

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
    }

    private struct PurchaseShippingLabelResultKey: Hashable {
        let siteID: Int64
    }

    private struct CheckLabelStatusResultKey: Hashable {
        let siteID: Int64
    }

    /// Set the value passed to the `completion` block if `loadShippingLabels` is called.
    func whenLoadingShippingLabels(siteID: Int64,
                                   orderID: Int64,
                                   thenReturn result: Result<OrderShippingLabelListResponse, Error>) {
        let key = LoadAllResultKey(siteID: siteID, orderID: orderID)
        let snapshot = result.map { ($0.shippingLabels, $0.settings) }
        state.withLock { $0.loadAllResults[key] = snapshot }
    }

    /// Set the value passed to the `completion` block if `printShippingLabel` is called.
    func whenPrintingShippingLabel(siteID: Int64,
                                   shippingLabelIDs: [Int64],
                                   paperSize: String,
                                   thenReturn result: Result<ShippingLabelPrintData, Error>) {
        let key = PrintResultKey(siteID: siteID, shippingLabelIDs: shippingLabelIDs, paperSize: paperSize)
        state.withLock { $0.printResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `refundShippingLabel` is called.
    func whenRefundingShippingLabel(siteID: Int64,
                                    orderID: Int64,
                                    shippingLabelID: Int64,
                                    thenReturn result: Result<ShippingLabelRefund, Error>) {
        let key = RefundResultKey(siteID: siteID, orderID: orderID, shippingLabelID: shippingLabelID)
        state.withLock { $0.refundResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `addressValidation` is called.
    func whenValidatingAddress(siteID: Int64,
                               thenReturn result: Result<ShippingLabelAddressValidationSuccess, Error>) {
        let key = AddressValidationResultKey(siteID: siteID)
        state.withLock { $0.addressValidationResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `packagesDetails` is called.
    func whenPackagesDetails(siteID: Int64,
                             thenReturn result: Result<ShippingLabelPackagesResponse, Error>) {
        let key = PackagesDetailsResultKey(siteID: siteID)
        state.withLock { $0.packagesDetailsResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `createPackage` is called.
    func whenCreatePackage(siteID: Int64,
                           thenReturn result: Result<Bool, Error>) {
        let key = CreatePackageResultKey(siteID: siteID)
        state.withLock { $0.createPackageResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadCarriersAndRates` is called.
    func whenLoadCarriersAndRates(siteID: Int64,
                           thenReturn result: Result<[ShippingLabelCarriersAndRates], Error>) {
        let key = LoadCarriersAndRatesKey(siteID: siteID)
        state.withLock { $0.loadCarriersAndRatesResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadShippingLabelAccountSettings` is called.
    func whenLoadShippingLabelAccountSettings(siteID: Int64,
                                       thenReturn result: Result<ShippingLabelAccountSettings, Error>) {
        let key = LoadAccountSettingsResultKey(siteID: siteID)
        state.withLock { $0.loadAccountSettings[key] = result }
    }

    /// Set the value passed to the `completion` block if `updateShippingLabelAccountSettings` is called.
    func whenUpdateShippingLabelAccountSettings(siteID: Int64,
                                                settings: ShippingLabelAccountSettings,
                                                thenReturn result: Result<Bool, Error>) {
        let key = UpdateAccountSettingsResultKey(siteID: siteID)
        state.withLock { $0.updateAccountSettings[key] = result }
    }

    func whenCheckingCreationEligiblity(siteID: Int64,
                                        orderID: Int64,
                                        thenReturn result: Result<ShippingLabelCreationEligibilityResponse, Error>) {
        let key = CreationEligibilityResultKey(siteID: siteID,
                                               orderID: orderID)
        state.withLock { $0.creationEligibilityResults[key] = result }
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
        state.withLock { $0.purchaseShippingLabelResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `checkLabelStatus` is called.
    func whenCheckLabelStatus(siteID: Int64,
                              orderID: Int64,
                              labelIDs: [Int64],
                              thenReturn result: Result<[ShippingLabelStatusPollingResponse], Error>) {
        let key = CheckLabelStatusResultKey(siteID: siteID)
        state.withLock { $0.checkLabelStatusResults[key] = result }
    }
}

// MARK: - ShippingLabelRemoteProtocol
extension MockShippingLabelRemote: ShippingLabelRemoteProtocol {
    func loadShippingLabels(siteID: Int64, orderID: Int64, completion: @escaping (Result<OrderShippingLabelListResponse, Error>) -> Void) {

        let key = LoadAllResultKey(siteID: siteID, orderID: orderID)
        if let result = state.withLock({ $0.loadAllResults[key] }) {
            completion(result.map { OrderShippingLabelListResponse(shippingLabels: $0.0, settings: $0.1) })
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func printShippingLabel(siteID: Int64,
                            shippingLabelIDs: [Int64],
                            paperSize: ShippingLabelPaperSize,
                            completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {

        let key = PrintResultKey(siteID: siteID, shippingLabelIDs: shippingLabelIDs, paperSize: paperSize.rawValue)
        if let result = state.withLock({ $0.printResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func refundShippingLabel(siteID: Int64, orderID: Int64, shippingLabelID: Int64, completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void) {

        let key = RefundResultKey(siteID: siteID, orderID: orderID, shippingLabelID: shippingLabelID)
        if let result = state.withLock({ $0.refundResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func addressValidation(siteID: Int64, address: ShippingLabelAddressVerification,
                           completion: @escaping (Result<ShippingLabelAddressValidationSuccess, Error>) -> Void) {

        let key = AddressValidationResultKey(siteID: siteID)
        if let result = state.withLock({ $0.addressValidationResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func packagesDetails(siteID: Int64, completion: @escaping (Result<ShippingLabelPackagesResponse, Error>) -> Void) {

        let key = PackagesDetailsResultKey(siteID: siteID)
        if let result = state.withLock({ $0.packagesDetailsResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func createPackage(siteID: Int64,
                       customPackage: ShippingLabelCustomPackage?,
                       predefinedOption: ShippingLabelPredefinedOption?,
                       completion: @escaping (Result<Bool, Error>) -> Void) {

        let key = CreatePackageResultKey(siteID: siteID)
        if let result = state.withLock({ $0.createPackageResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadCarriersAndRates(siteID: Int64,
                              orderID: Int64,
                              originAddress: ShippingLabelAddress,
                              destinationAddress: ShippingLabelAddress,
                              packages: [ShippingLabelPackageSelected],
                              completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        let key = LoadCarriersAndRatesKey(siteID: siteID)

        if let result = state.withLock({ $0.loadCarriersAndRatesResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadShippingLabelAccountSettings(siteID: Int64, completion: @escaping (Result<ShippingLabelAccountSettings, Error>) -> Void) {

        let key = LoadAccountSettingsResultKey(siteID: siteID)
        if let result = state.withLock({ $0.loadAccountSettings[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func updateShippingLabelAccountSettings(siteID: Int64,
                                            settings: ShippingLabelAccountSettings,
                                            completion: @escaping (Result<Bool, Error>) -> Void) {

        let key = UpdateAccountSettingsResultKey(siteID: siteID)
        if let result = state.withLock({ $0.updateAccountSettings[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  completion: @escaping (Result<ShippingLabelCreationEligibilityResponse, Error>) -> Void) {

        let key = CreationEligibilityResultKey(siteID: siteID,
                                               orderID: orderID)
        if let result = state.withLock({ $0.creationEligibilityResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: ShippingLabelAddress,
                               destinationAddress: ShippingLabelAddress,
                               packages: [ShippingLabelPackagePurchase],
                               emailCustomerReceipt: Bool,
                               completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void) {

        let key = PurchaseShippingLabelResultKey(siteID: siteID)
        if let result = state.withLock({ $0.purchaseShippingLabelResults[key] }) {
            state.withLock { $0.purchaseShippingLabelCalled = true }
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func checkLabelStatus(siteID: Int64,
                          orderID: Int64,
                          labelIDs: [Int64],
                          completion: @escaping (Result<[ShippingLabelStatusPollingResponse], Error>) -> Void) {

        let key = CheckLabelStatusResultKey(siteID: siteID)
        if let result = state.withLock({ $0.checkLabelStatusResults[key] }) {
            state.withLock { $0.checkLabelStatusCallsCount += 1 }
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }
}
