import Networking
import XCTest

/// Mock for `WooShippingRemote`.
///
final class MockWooShippingRemote {

    private struct ResultKey: Hashable {
        let siteID: Int64
    }

    /// The results to return based on the given arguments in `createPackage`
    private var createPackageResults = [ResultKey: Result<WooShippingCreatePackageResponse, Error>]()

    /// The results to return based on the given arguments in `loadLabelRates`
    private var loadLabelRatesResults = [ResultKey: Result<[ShippingLabelCarriersAndRates], Error>]()

    /// The results to return based on the given arguments in `purchaseShippingLabel`
    private var purchaseShippingLabelResults = [ResultKey: Result<[ShippingLabelPurchase], Error>]()

    /// The results to return based on the given arguments in `loadPackages`
    private var loadPackagesResults = [ResultKey: Result<WooShippingPackagesResponse, Error>]()

    /// The results to return based on the given arguments in `loadAccountSettings`
    private var loadAccountSettingsResults = [ResultKey: Result<WooShippingAccountSettingsResponse, Error>]()

    /// The results to return based on the given arguments in `checkLabelStatus`
    private var checkLabelStatus = [ResultKey: Result<ShippingLabelStatusPollingResponse, Error>]()

    /// Set the value passed to the `completion` block if `createPackage` is called.
    func whenCreatePackage(siteID: Int64,
                           thenReturn result: Result<WooShippingCreatePackageResponse, Error>) {
        let key = ResultKey(siteID: siteID)
        createPackageResults[key] = result
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
                                 thenReturn result: Result<WooShippingAccountSettingsResponse, Error>) {
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
                             completion: @escaping (Result<WooShippingAccountSettingsResponse, Error>) -> Void) {
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
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
