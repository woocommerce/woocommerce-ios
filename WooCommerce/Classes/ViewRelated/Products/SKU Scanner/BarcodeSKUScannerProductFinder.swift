import Foundation
import Yosemite
import Vision

/// Given a scanned barcode searches for the matching product, refining the barcode if necessary to handle the format exceptions
///
struct BarcodeSKUScannerProductFinder {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func findProduct(from barcode: ScannedBarcode, siteID: Int64) async throws -> Product {
        do {
            return try await retrieveProduct(from: barcode.payloadStringValue, siteID: siteID)
        } catch {
            guard (error as? ProductLoadError) == .notFound else {
                throw error
            }

            if let refinedBarcode = barcode.convertToUPCAFormatIfPossible() {
                // Re-start the search in case we can convert the barcode to UPC-A (Apple doesn't provide this format)
                return try await findProduct(from: refinedBarcode, siteID: siteID)
            } else if let refinedBarcode = barcode.removeCheckDigitIfPossible() {
                // Try one more time if we can remove the barcode check digit, as some merchants might have added the SKU without it
                return try await retrieveProduct(from: refinedBarcode.payloadStringValue, siteID: siteID)
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

private extension ScannedBarcode {
    func removeCheckDigitIfPossible() -> ScannedBarcode? {
        guard symbology == VNBarcodeSymbology.upce ||
              symbology == VNBarcodeSymbology.ean13 else {
            return nil
        }

        return ScannedBarcode(payloadStringValue: String(payloadStringValue.dropLast()), symbology: symbology)
    }

    func convertToUPCAFormatIfPossible() -> ScannedBarcode? {
        // When we have an UPC-A format barcode Apple adds a zero at the beginning and returns an EAN-13 format
        guard symbology == VNBarcodeSymbology.ean13,
              payloadStringValue.hasPrefix("0") else {
            return nil
        }

        return ScannedBarcode(payloadStringValue: String(payloadStringValue.dropFirst()), symbology: symbology)
    }
}
