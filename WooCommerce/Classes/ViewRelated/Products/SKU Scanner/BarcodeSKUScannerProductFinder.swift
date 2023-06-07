import Foundation
import Yosemite
import Vision

struct BarcodeSKUScannerProductFinder {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func findProduct(from barcode: ScannedBarcode, siteID: Int64) async throws -> Product {
        var retryWasTriggered = false

        do {
            return try await retrieveProduct(from: barcode.payloadStringValue, siteID: siteID)
        } catch {
            if !retryWasTriggered,
               (error as? ProductLoadError) == .notFound,
               barcode.shouldRetryWithoutTheLastDigitWhenSearchingBySKU {
                retryWasTriggered = true

                return try await retrieveProduct(from: String(barcode.payloadStringValue.dropLast()), siteID: siteID)
            } else {
                throw error
            }
        }
    }

    private func retrieveProduct(from sku: String, siteID: Int64) async throws -> Product {
        try await withCheckedThrowingContinuation { continuation in
            let action = ProductAction.retrieveFirstProductMatchFromSKU(siteID: siteID,
                                                                        sku: sku) { result in
                switch result {
                case let .success(matchedProduct):
                    continuation.resume(returning: matchedProduct)
                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}

extension ScannedBarcode {
    var shouldRetryWithoutTheLastDigitWhenSearchingBySKU: Bool {
        symbology == VNBarcodeSymbology.upce ||
        symbology == VNBarcodeSymbology.ean13
    }
}
