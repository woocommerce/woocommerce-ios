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
            // If we couldn't find the product, let's do tries by refining the SKU search
            guard (error as? ProductLoadError) == .notFound else {
                throw error
            }

            // Re-start the search in case we can remove the country code (Apple adds it by default, but merchants might not have it)
            if let refinedBarcode = barcode.removeCountryCodeIfPossible() {
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

    func removeCountryCodeIfPossible() -> ScannedBarcode? {
        // When we have an 12 digit UPC-A format barcode Apple adds a zero at the beginning and returns an EAN-13 format
        // See https://nationwidebarcode.com/are-upc-a-and-ean-13-the-same/
        guard symbology == VNBarcodeSymbology.ean13,
              payloadStringValue.hasPrefix("0") else {
            return nil
        }

        return ScannedBarcode(payloadStringValue: String(payloadStringValue.dropFirst()), symbology: symbology)
    }
}
