import Foundation
import Yosemite

/// Given a scanned barcode this struct searches for the matching product, refining the barcode if necessary to handle the format exceptions
///
struct BarcodeSKUScannerProductFinder {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func findProduct(from barcode: ScannedBarcode, siteID: Int64, source: WooAnalyticsEvent.Orders.BarcodeScanningSource) async throws -> Product {
        do {
            let product = try await retrieveProduct(from: barcode.payloadStringValue, siteID: siteID)
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.barcodeScanningSearchViaSKUSuccess(from: source))

            return product
        } catch {
            ServiceLocator.analytics.track(event: WooAnalyticsEvent.Orders.barcodeScanningSearchViaSKUFailure(from: source,
                                                                                                              symbology: barcode.symbology,
                                                                                                              reason: error.localizedDescription))

            // If we couldn't find the product, let's keep trying by refining the SKU search
            guard (error as? ProductLoadError) == .notFound else {
                throw error
            }

            // Re-start the search in case we can remove the country code (Apple adds it by default for UPC-A, but merchants might not have it)
            if let refinedBarcode = barcode.removeCountryCodeIfPossible() {
                return try await findProduct(from: refinedBarcode, siteID: siteID, source: source)
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
        guard symbology == BarcodeSymbology.upce ||
              symbology == BarcodeSymbology.ean13 else {
            return nil
        }

        return ScannedBarcode(payloadStringValue: String(payloadStringValue.dropLast()), symbology: symbology)
    }

    func removeCountryCodeIfPossible() -> ScannedBarcode? {
        // When we have an 12 digit UPC-A format barcode Apple adds a zero at the beginning as the country code and returns an EAN-13 format
        // See https://nationwidebarcode.com/are-upc-a-and-ean-13-the-same/
        guard symbology == BarcodeSymbology.ean13,
              payloadStringValue.characterCount == 13,
              payloadStringValue.hasPrefix("0") else {
            return nil
        }

        return ScannedBarcode(payloadStringValue: String(payloadStringValue.dropFirst()), symbology: symbology)
    }
}
