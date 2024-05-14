import Foundation
import Yosemite
import protocol WooFoundation.Analytics

/// Given a scanned barcode this struct searches for the matching product or variation, refining the barcode if necessary to handle the format exceptions
///
struct BarcodeSKUScannerItemFinder {
    private let stores: StoresManager
    private let analytics: Analytics

    init(stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics) {
        self.stores = stores
        self.analytics = analytics
    }

    func searchBySKU(from barcode: ScannedBarcode, siteID: Int64, source: WooAnalyticsEvent.BarcodeScanning.Source) async throws -> SKUSearchResult {
        do {
            let result = try await search(by: barcode.payloadStringValue, siteID: siteID)
            analytics.track(event: WooAnalyticsEvent.BarcodeScanning.productSearchViaSKUSuccess(from: source.rawValue))

            return result
        } catch {
            analytics.track(event: WooAnalyticsEvent.BarcodeScanning.productSearchViaSKUFailure(from: source.rawValue,
                                                                                            symbology: barcode.symbology,
                                                                                            reason: trackingReason(for: error)))

            // If we couldn't find the product, let's keep trying by refining the SKU search
            guard (error as? ProductLoadError) == .notFound else {
                throw error
            }

            // Re-start the search in case we can remove the country code (Apple adds it by default for UPC-A, but merchants might not have it)
            if let refinedBarcode = barcode.removeCountryCodeIfPossible() {
                return try await searchBySKU(from: refinedBarcode, siteID: siteID, source: source)
            } else if let refinedBarcode = barcode.removeCheckDigitIfPossible() {
                // Try one more time if we can remove the barcode check digit, as some merchants might have added the SKU without it
                return try await search(by: refinedBarcode.payloadStringValue, siteID: siteID)
            } else {
                throw error
            }
        }
    }

    private func search(by sku: String, siteID: Int64) async throws -> SKUSearchResult {
        try await withCheckedThrowingContinuation { continuation in
            let action = ProductAction.retrieveFirstPurchasableItemMatchFromSKU(siteID: siteID,
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

    private func trackingReason(for error: Error) -> String {
        guard let productLoadError = error as? ProductLoadError else {
            return error.localizedDescription
        }

        return productLoadError.trackingReason
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

private extension ProductLoadError {
    var trackingReason: String {
        switch self {
        case .notFound:
            return "Product not found"
        case .notPurchasable:
            return "Product not purchasable"
        default:
            return localizedDescription
        }
    }
}
