import Networking
import Synchronization
import XCTest

/// Mock for `WooShippingRemote`.
///
final class MockWooShippingRemote: Sendable {
    private struct State {
        var purchaseShippingLabelCalled = false
        var checkLabelStatusCallsCount = 0
        var checkEligibilityResults = [ResultKey: Result<ShippingLabelCreationEligibilityResponse, Error>]()
        var createPackageResults = [ResultKey: Result<WooShippingCreatePackageResponse, Error>]()
        var deletePackageResults = [ResultKey: Result<WooShippingCreatePackageResponse, Error>]()
        var loadLabelRatesResults = [ResultKey: Result<[ShippingLabelCarriersAndRates], Error>]()
        var purchaseShippingLabelResults = [ResultKey: Result<[ShippingLabelPurchase], Error>]()
        var loadPackagesResults = [ResultKey: Result<WooShippingPackagesResponse, Error>]()
        var loadAccountSettingsResults = [ResultKey: Result<WooShippingAccountSettings, Error>]()
        var updateAccountSettingsResults = [ResultKey: Result<Bool, Error>]()
        var checkLabelStatus = [ResultKey: Result<ShippingLabelStatusPollingResponse, Error>]()
        var printLabel = [ResultKey: Result<ShippingLabelPrintData, Error>]()
        var loadOriginAddresses = [ResultKey: Result<[WooShippingOriginAddress], Error>]()
        var addressValidation = [ResultKey: Result<WooShippingAddressValidationSuccess, Error>]()
        var updateOriginAddress = [ResultKey: Result<WooShippingOriginAddressUpdate, Error>]()
        var verifyDestinationAddress = [ResultKey: Result<WooShippingVerifyDestinationAddressSuccess, Error>]()
        var updateDestinationAddress = [ResultKey: Result<WooShippingDestinationAddressUpdate, Error>]()
        var loadConfig = [ResultKey: Result<WooShippingConfig, Error>]()
        var loadCustomsRequirements = [ResultKey: Result<Bool, Error>]()
        var loadEUProductIdentifiers = [ResultKey: Result<[WooShippingEUProductIdentifiers], Error>]()
        var updateShipment = [ResultKey: Result<WooShippingShipments, Error>]()
        var refundShippingLabel = [RefundResultKey: Result<ShippingLabelRefund, Error>]()
        var acceptUPSTermsOfService = [AcceptUPSTOSKey: Result<Bool, Error>]()
        var acceptFedExTermsOfService = [ResultKey: Result<Bool, Error>]()
    }

    private let state = Mutex(State())

    var purchaseShippingLabelCalled: Bool { state.withLock { $0.purchaseShippingLabelCalled } }
    var checkLabelStatusCallsCount: Int { state.withLock { $0.checkLabelStatusCallsCount } }

    private struct ResultKey: Hashable {
        let siteID: Int64
    }

    private struct RefundResultKey: Hashable {
        let siteID: Int64
        let orderID: Int64
        let shippingLabelID: Int64
    }

    private struct AcceptUPSTOSKey: Hashable {
        let siteID: Int64
        let originAddress: WooShippingAddress
    }

    /// Set the value passed to the `completion` block if `createPackage` is called.
    func whenCheckEligibility(siteID: Int64,
                              orderID: Int64,
                              thenReturn result: Result<ShippingLabelCreationEligibilityResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.checkEligibilityResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `createPackage` is called.
    func whenCreatePackage(siteID: Int64,
                           thenReturn result: Result<WooShippingCreatePackageResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.createPackageResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `deletePackage` is called.
    func whenDeletePackage(siteID: Int64,
                           thenReturn result: Result<WooShippingCreatePackageResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.deletePackageResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadLabelRates` is called.
    func whenLoadLabelRates(siteID: Int64,
                            thenReturn result: Result<[ShippingLabelCarriersAndRates], Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.loadLabelRatesResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadPackages` is called.
    func whenLoadPackages(siteID: Int64,
                          thenReturn result: Result<WooShippingPackagesResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.loadPackagesResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadAccountSettings` is called.
    func whenLoadAccountSettings(siteID: Int64,
                                 thenReturn result: Result<WooShippingAccountSettings, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.loadAccountSettingsResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `updateAccountSettings` is called.
    func whenUpdateAccountSettings(siteID: Int64, thenReturn result: Result<Bool, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.updateAccountSettingsResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `purchaseShippingLabel` is called.
    func whenPurchaseShippingLabel(siteID: Int64,
                                   thenReturn result: Result<[ShippingLabelPurchase], Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.purchaseShippingLabelResults[key] = result }
    }

    /// Set the value passed to the `completion` block if `checkLabelStatus` is called.
    func whenCheckLabelStatus(siteID: Int64,
                              thenReturn result: Result<ShippingLabelStatusPollingResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.checkLabelStatus[key] = result }
    }

    /// Set the value passed to the `completion` block if `printLabel` is called.
    func whenPrintLabel(siteID: Int64,
                        thenReturn result: Result<ShippingLabelPrintData, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.printLabel[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadOriginAddresses` is called.
    func whenOriginAddresses(siteID: Int64,
                             thenReturn result: Result<[WooShippingOriginAddress], Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.loadOriginAddresses[key] = result }
    }

    /// Set the value passed to the `completion` block if `addressValidation` is called.
    func whenAddressValidation(siteID: Int64,
                               thenReturn result: Result<WooShippingAddressValidationSuccess, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.addressValidation[key] = result }
    }

    /// Set the value passed to the `completion` block if `updateOriginAddress` is called.
    func whenUpdatingOriginAddress(siteID: Int64,
                                   thenReturn result: Result<WooShippingOriginAddressUpdate, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.updateOriginAddress[key] = result }
    }

    /// Set the value passed to the `completion` block if `verifyDestinationAddress` is called.
    func whenVerifyDestinationAddress(siteID: Int64,
                                      thenReturn result: Result<WooShippingVerifyDestinationAddressSuccess, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.verifyDestinationAddress[key] = result }
    }

    /// Set the value passed to the `completion` block if `updateDestinationAddress` is called.
    func whenUpdatingDestinationAddress(siteID: Int64,
                                        thenReturn result: Result<WooShippingDestinationAddressUpdate, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.updateDestinationAddress[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadConfig` is called.
    func whenLoadingConfig(siteID: Int64,
                           thenReturn result: Result<WooShippingConfig, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.loadConfig[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadCustomsRequirements` is called.
    func whenLoadingCustomsRequirements(siteID: Int64,
                                        thenReturn result: Result<Bool, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.loadCustomsRequirements[key] = result }
    }

    /// Set the value passed to the `completion` block if `loadEUProductIdentifiers` is called.
    func whenLoadingEUProductIdentifiers(siteID: Int64,
                                         thenReturn result: Result<[WooShippingEUProductIdentifiers], Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.loadEUProductIdentifiers[key] = result }
    }

    /// Set the value passed to the `completion` block if `updateShipment` is called.
    func whenUpdatingShipment(siteID: Int64,
                              thenReturn result: Result<WooShippingShipments, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.updateShipment[key] = result }
    }

    /// Set the value passed to the `completion` block if `refundShippingLabel` is called.
    func whenRefundingShippingLabel(siteID: Int64,
                                    orderID: Int64,
                                    shippingLabelID: Int64,
                                    thenReturn result: Result<ShippingLabelRefund, Error>) {
        let key = RefundResultKey(siteID: siteID, orderID: orderID, shippingLabelID: shippingLabelID)
        state.withLock { $0.refundShippingLabel[key] = result }
    }

    /// Set the value passed to the `completion` block if `acceptUPSTermsOfService` is called
    func whenAcceptingUPSTOS(siteID: Int64,
                             originAddress: WooShippingAddress,
                             thenReturn result: Result<Bool, Error>) {
        let key = AcceptUPSTOSKey(siteID: siteID, originAddress: originAddress)
        state.withLock { $0.acceptUPSTermsOfService[key] = result }
    }

    /// Set the value passed to the `completion` block if `acceptFedExTermsOfService` is called
    func whenAcceptingFedExTOS(siteID: Int64,
                               thenReturn result: Result<Bool, Error>) {
        let key = ResultKey(siteID: siteID)
        state.withLock { $0.acceptFedExTermsOfService[key] = result }
    }
}

// MARK: - WooShippingRemoteProtocol
extension MockWooShippingRemote: WooShippingRemoteProtocol {
    func checkCreationEligibility(siteID: Int64,
                                  orderID: Int64,
                                  completion: @escaping (Result<Networking.ShippingLabelCreationEligibilityResponse, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.checkEligibilityResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func createPackage(siteID: Int64,
                       customPackage: Networking.WooShippingCustomPackage?,
                       predefinedOption: Networking.WooShippingPredefinedSavedOption?,
                       completion: @escaping (Result<Networking.WooShippingCreatePackageResponse, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.createPackageResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func deletePackage(siteID: Int64,
                       packageID: String,
                       packageType: WooShippingPackageType,
                       completion: @escaping (Result<Networking.WooShippingCreatePackageResponse, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.deletePackageResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadLabelRates(siteID: Int64,
                        orderID: Int64,
                        originAddress: WooShippingAddress,
                        destinationAddress: WooShippingAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.loadLabelRatesResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadPackages(siteID: Int64,
                      completion: @escaping (Result<Networking.WooShippingPackagesResponse, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.loadPackagesResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadAccountSettings(siteID: Int64,
                             completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.loadAccountSettingsResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func updateAccountSettings(siteID: Int64,
                               settings: ShippingLabelAccountSettings,
                               completion: @escaping (Result<Bool, any Error>) -> Void) {
        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.updateAccountSettingsResults[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: Networking.WooShippingAddress,
                               destinationAddress: Networking.WooShippingAddress,
                               package: Networking.WooShippingPackagePurchase,
                               markOrderComplete: Bool?,
                               completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.purchaseShippingLabelResults[key] }) {
            state.withLock { $0.purchaseShippingLabelCalled = true }
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func checkLabelStatus(siteID: Int64,
                          orderID: Int64,
                          labelID: Int64,
                          completion: @escaping (Result<ShippingLabelStatusPollingResponse, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.checkLabelStatus[key] }) {
            state.withLock { $0.checkLabelStatusCallsCount += 1 }
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func printLabel(siteID: Int64,
                    labelIDs: [Int64],
                    paperSize: Networking.ShippingLabelPaperSize,
                    completion: @escaping (Result<Networking.ShippingLabelPrintData, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.printLabel[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadOriginAddresses(siteID: Int64,
                             completion: @escaping (Result<[Networking.WooShippingOriginAddress], any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.loadOriginAddresses[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func addressValidation(siteID: Int64,
                           address: WooShippingAddress,
                           completion: @escaping (Result<WooShippingAddressValidationSuccess, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.addressValidation[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func updateOriginAddress(siteID: Int64,
                             address: WooShippingOriginAddress,
                             isVerified: Bool,
                             completion: @escaping (Result<WooShippingOriginAddressUpdate, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.updateOriginAddress[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func verifyDestinationAddress(siteID: Int64,
                                  orderID: Int64,
                                  completion: @escaping (Result<WooShippingVerifyDestinationAddressSuccess, Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.verifyDestinationAddress[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func updateDestinationAddress(siteID: Int64,
                                  orderID: Int64,
                                  address: WooShippingDestinationAddress,
                                  isVerified: Bool,
                                  completion: @escaping (Result<WooShippingDestinationAddressUpdate, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.updateDestinationAddress[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadConfig(siteID: Int64,
                    orderID: Int64,
                    completion: @escaping (Result<WooShippingConfig, Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.loadConfig[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadCustomsRequirements(siteID: Int64,
                                 orderID: Int64,
                                 originID: String?,
                                 completion: @escaping (Result<Bool, Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.loadCustomsRequirements[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func loadEUProductIdentifiers(siteID: Int64,
                                  orderID: Int64,
                                  completion: @escaping (Result<[WooShippingEUProductIdentifiers], Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.loadEUProductIdentifiers[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func updateShipment(siteID: Int64,
                        orderID: Int64,
                        shipmentToUpdate: WooShippingUpdateShipment,
                        completion: @escaping (Result<WooShippingShipments, any Error>) -> Void) {

        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.updateShipment[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func refundShippingLabel(siteID: Int64,
                             orderID: Int64,
                             shippingLabelID: Int64,
                             completion: @escaping (Result<ShippingLabelRefund, Error>) -> Void) {
        let key = RefundResultKey(siteID: siteID, orderID: orderID, shippingLabelID: shippingLabelID)
        if let result = state.withLock({ $0.refundShippingLabel[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func acceptUPSTermsOfService(siteID: Int64,
                                 originAddress: WooShippingAddress,
                                 completion: @escaping (Result<Bool, Error>) -> Void) {
        let key = AcceptUPSTOSKey(siteID: siteID, originAddress: originAddress)
        if let result = state.withLock({ $0.acceptUPSTermsOfService[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }

    func acceptFedExTermsOfService(siteID: Int64,
                                   completion: @escaping (Result<Bool, Error>) -> Void) {
        let key = ResultKey(siteID: siteID)
        if let result = state.withLock({ $0.acceptFedExTermsOfService[key] }) {
            completion(result)
        } else {
            XCTFail("\(String(describing: self)) Could not find Result for \(key)")
        }
    }
}
