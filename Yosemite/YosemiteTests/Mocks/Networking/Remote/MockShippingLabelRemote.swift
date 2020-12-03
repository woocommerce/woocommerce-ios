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

    /// The results to return based on the given arguments in `loadShippingLabels`
    private var loadAllResults = [LoadAllResultKey: Result<OrderShippingLabelListResponse, Error>]()

    /// The results to return based on the given arguments in `printShippingLabel`
    private var printResults = [PrintResultKey: Result<ShippingLabelPrintData, Error>]()

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
}
