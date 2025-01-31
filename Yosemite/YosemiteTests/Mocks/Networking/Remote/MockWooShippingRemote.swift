import Networking
import XCTest

/// Mock for `WooShippingRemote`.
///
final class MockWooShippingRemote {

    private(set) var purchaseShippingLabelCalled = false
    private(set) var checkLabelStatusCallsCount = 0

    private struct ResultKey: Hashable {
        let siteID: Int64
    }

    /// The results to return based on the given arguments in `createPackage`
    private var createPackageResults = [ResultKey: Result<WooShippingCreatePackageResponse, Error>]()

    /// The results to return based on the given arguments in `deletePackage`
    private var deletePackageResults = [ResultKey: Result<WooShippingCreatePackageResponse, Error>]()

    /// The results to return based on the given arguments in `loadLabelRates`
    private var loadLabelRatesResults = [ResultKey: Result<[ShippingLabelCarriersAndRates], Error>]()

    /// The results to return based on the given arguments in `purchaseShippingLabel`
    private var purchaseShippingLabelResults = [ResultKey: Result<[ShippingLabelPurchase], Error>]()

    /// The results to return based on the given arguments in `loadPackages`
    private var loadPackagesResults = [ResultKey: Result<WooShippingPackagesResponse, Error>]()

    /// The results to return based on the given arguments in `loadAccountSettings`
    private var loadAccountSettingsResults = [ResultKey: Result<WooShippingAccountSettings, Error>]()

    /// The results to return based on the given arguments in `checkLabelStatus`
    private var checkLabelStatus = [ResultKey: Result<ShippingLabelStatusPollingResponse, Error>]()

    /// The results to return based on the given arguments in `printLabel`
    private var printLabel = [ResultKey: Result<ShippingLabelPrintData, Error>]()

    /// The results to return based on the given arguments in `loadOriginAddresses`
    private var loadOriginAddresses = [ResultKey: Result<[WooShippingOriginAddress], Error>]()

    /// The results to return based on the given arguments in `addressValidation`
    private var addressValidation = [ResultKey: Result<WooShippingAddressValidationSuccess, Error>]()

    /// The results to return based on the given arguments in `updateOriginAddress`
    private var updateOriginAddress = [ResultKey: Result<WooShippingOriginAddressUpdate, Error>]()

    /// Set the value passed to the `completion` block if `createPackage` is called.
    func whenCreatePackage(siteID: Int64,
                           thenReturn result: Result<WooShippingCreatePackageResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        createPackageResults[key] = result
    }

    /// Set the value passed to the `completion` block if `deletePackage` is called.
    func whenDeletePackage(siteID: Int64,
                           thenReturn result: Result<WooShippingCreatePackageResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        deletePackageResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadLabelRates` is called.
    func whenLoadLabelRates(siteID: Int64,
                            thenReturn result: Result<[ShippingLabelCarriersAndRates], Error>) {
        let key = ResultKey(siteID: siteID)
        loadLabelRatesResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadPackages` is called.
    func whenLoadPackages(siteID: Int64,
                          thenReturn result: Result<WooShippingPackagesResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        loadPackagesResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadAccountSettings` is called.
    func whenLoadAccountSettings(siteID: Int64,
                                 thenReturn result: Result<WooShippingAccountSettings, Error>) {
        let key = ResultKey(siteID: siteID)
        loadAccountSettingsResults[key] = result
    }

    /// Set the value passed to the `completion` block if `purchaseShippingLabel` is called.
    func whenPurchaseShippingLabel(siteID: Int64,
                                   thenReturn result: Result<[ShippingLabelPurchase], Error>) {
        let key = ResultKey(siteID: siteID)
        purchaseShippingLabelResults[key] = result
    }

    /// Set the value passed to the `completion` block if `checkLabelStatus` is called.
    func whenCheckLabelStatus(siteID: Int64,
                              thenReturn result: Result<ShippingLabelStatusPollingResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        checkLabelStatus[key] = result
    }

    /// Set the value passed to the `completion` block if `printLabel` is called.
    func whenPrintLabel(siteID: Int64,
                        thenReturn result: Result<ShippingLabelPrintData, Error>) {
        let key = ResultKey(siteID: siteID)
        printLabel[key] = result
    }

    /// Set the value passed to the `completion` block if `loadOriginAddresses` is called.
    func whenOriginAddresses(siteID: Int64,
                             thenReturn result: Result<[WooShippingOriginAddress], Error>) {
        let key = ResultKey(siteID: siteID)
        loadOriginAddresses[key] = result
    }

    /// Set the value passed to the `completion` block if `addressValidation` is called.
    func whenAddressValidation(siteID: Int64,
                               thenReturn result: Result<WooShippingAddressValidationSuccess, Error>) {
        let key = ResultKey(siteID: siteID)
        addressValidation[key] = result
    }

    /// Set the value passed to the `completion` block if `updateOriginAddress` is called.
    func whenUpdatingOriginAddress(siteID: Int64,
                                   thenReturn result: Result<WooShippingOriginAddressUpdate, Error>) {
        let key = ResultKey(siteID: siteID)
        updateOriginAddress[key] = result
    }
}

// MARK: - WooShippingRemoteProtocol
extension MockWooShippingRemote: WooShippingRemoteProtocol {
    func createPackage(siteID: Int64,
                       customPackage: Networking.WooShippingCustomPackage?,
                       predefinedOption: Networking.WooShippingPredefinedSavedOption?,
                       completion: @escaping (Result<Networking.WooShippingCreatePackageResponse, any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.createPackageResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func deletePackage(siteID: Int64, packageID: String, completion: @escaping (Result<Networking.WooShippingCreatePackageResponse, any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.deletePackageResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func loadLabelRates(siteID: Int64,
                        orderID: Int64,
                        originAddress: ShippingLabelAddress,
                        destinationAddress: ShippingLabelAddress,
                        packages: [ShippingLabelPackageSelected],
                        completion: @escaping (Result<[ShippingLabelCarriersAndRates], Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.loadLabelRatesResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func loadPackages(siteID: Int64,
                      completion: @escaping (Result<Networking.WooShippingPackagesResponse, any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.loadPackagesResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func loadAccountSettings(siteID: Int64,
                             completion: @escaping (Result<WooShippingAccountSettings, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.loadAccountSettingsResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func purchaseShippingLabel(siteID: Int64,
                               orderID: Int64,
                               originAddress: Networking.ShippingLabelAddress,
                               destinationAddress: Networking.ShippingLabelAddress,
                               package: Networking.WooShippingPackagePurchase,
                               completion: @escaping (Result<[ShippingLabelPurchase], Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.purchaseShippingLabelResults[key] {
                self.purchaseShippingLabelCalled = true
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func checkLabelStatus(siteID: Int64,
                          orderID: Int64,
                          labelID: Int64,
                          completion: @escaping (Result<ShippingLabelStatusPollingResponse, any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.checkLabelStatus[key] {
                self.checkLabelStatusCallsCount += 1
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func printLabel(siteID: Int64,
                    labelIDs: [Int64],
                    paperSize: Networking.ShippingLabelPaperSize,
                    completion: @escaping (Result<Networking.ShippingLabelPrintData, any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.printLabel[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func loadOriginAddresses(siteID: Int64,
                             completion: @escaping (Result<[Networking.WooShippingOriginAddress], any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.loadOriginAddresses[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func addressValidation(siteID: Int64,
                           address: ShippingLabelAddress,
                           completion: @escaping (Result<WooShippingAddressValidationSuccess, any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.addressValidation[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }

    func updateOriginAddress(siteID: Int64,
                             address: WooShippingOriginAddress,
                             isVerified: Bool,
                             completion: @escaping (Result<WooShippingOriginAddressUpdate, any Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = ResultKey(siteID: siteID)
            if let result = self.updateOriginAddress[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
