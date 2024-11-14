import Networking
import XCTest

/// Mock for `WooShippingRemote`.
///
final class MockWooShippingRemote {

    private struct CreatePackageResultKey: Hashable {
        let siteID: Int64
    }

    /// The results to return based on the given arguments in `createPackage`
    private var createPackageResults = [CreatePackageResultKey: Result<WooShippingCreatePackageResponse, Error>]()

    /// The results to return based on the given arguments in `loadLabelRates`
    private var loadLabelRatesResults = [CreatePackageResultKey: Result<[ShippingLabelCarriersAndRates], Error>]()

    /// The results to return based on the given arguments in `loadLabelRates`
    private var loadPackagesResults = [CreatePackageResultKey: Result<WooShippingPackagesResponse, Error>]()

    /// Set the value passed to the `completion` block if `createPackage` is called.
    func whenCreatePackage(siteID: Int64,
                           thenReturn result: Result<WooShippingCreatePackageResponse, Error>) {
        let key = CreatePackageResultKey(siteID: siteID)
        createPackageResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadLabelRates` is called.
    func whenLoadLabelRates(siteID: Int64,
                            thenReturn result: Result<[ShippingLabelCarriersAndRates], Error>) {
        let key = CreatePackageResultKey(siteID: siteID)
        loadLabelRatesResults[key] = result
    }

    /// Set the value passed to the `completion` block if `loadPackages` is called.
    func whenLoadPackages(siteID: Int64,
                          thenReturn result: Result<WooShippingPackagesResponse, Error>) {
        let key = CreatePackageResultKey(siteID: siteID)
        loadPackagesResults[key] = result
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

            let key = CreatePackageResultKey(siteID: siteID)
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

            let key = CreatePackageResultKey(siteID: siteID)
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

            let key = CreatePackageResultKey(siteID: siteID)
            if let result = self.loadPackagesResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
