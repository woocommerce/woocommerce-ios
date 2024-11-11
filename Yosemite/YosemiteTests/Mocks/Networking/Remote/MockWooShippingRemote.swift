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

    /// Set the value passed to the `completion` block if `createPackage` is called.
    func whenCreatePackage(siteID: Int64,
                           thenReturn result: Result<WooShippingCreatePackageResponse, Error>) {
        let key = CreatePackageResultKey(siteID: siteID)
        createPackageResults[key] = result
    }
}

// MARK: - WooShippingRemoteProtocol
extension MockWooShippingRemote: WooShippingRemoteProtocol {
    func createPackage(siteID: Int64,
                       customPackage: Networking.WooShippingCustomPackage?,
                       predefinedOption: Networking.WooShippingPredefinedOption?,
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
}
