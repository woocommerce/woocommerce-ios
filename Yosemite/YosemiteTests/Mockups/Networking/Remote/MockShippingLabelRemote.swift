import Foundation
import Networking

import XCTest

/// Mock for `ShippingLabelRemote`.
///
final class MockShippingLabelRemote {
    private struct PrintResultKey: Hashable {
        let siteID: Int64
        let shippingLabelID: Int64
        let paperSize: String
    }

    /// The results to return based on the given arguments in `loadProduct`
    private var printResults = [PrintResultKey: Result<ShippingLabelPrintData, Error>]()

    /// Set the value passed to the `completion` block if `printShippingLabel` is called.
    ///
    func whenPrintingShippingLabel(siteID: Int64,
                                   shippingLabelID: Int64,
                                   paperSize: String,
                                   thenReturn result: Result<ShippingLabelPrintData, Error>) {
        let key = PrintResultKey(siteID: siteID, shippingLabelID: shippingLabelID, paperSize: paperSize)
        printResults[key] = result
    }
}

// MARK: - ShippingLabelRemoteProtocol
extension MockShippingLabelRemote: ShippingLabelRemoteProtocol {
    func printShippingLabel(siteID: Int64, shippingLabelID: Int64, paperSize: String, completion: @escaping (Result<ShippingLabelPrintData, Error>) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            let key = PrintResultKey(siteID: siteID, shippingLabelID: shippingLabelID, paperSize: paperSize)
            if let result = self.printResults[key] {
                completion(result)
            } else {
                XCTFail("\(String(describing: self)) Could not find Result for \(key)")
            }
        }
    }
}
