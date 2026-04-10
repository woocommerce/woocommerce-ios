import Foundation
import enum Yosemite.PointOfSaleBarcodeScanError

extension Cart {
    @discardableResult
    mutating func updateLoadingItem(id: UUID, with error: PointOfSaleBarcodeScanError) -> Cart.PurchasableItem? {
        guard let index = purchasableItems.firstIndex(where: { $0.id == id }) else { return nil }

        purchasableItems[index] = errorItem(id: id, error: error)

        return purchasableItems[index]
    }

    @discardableResult
    mutating func addErrorItem(error: PointOfSaleBarcodeScanError) -> Cart.PurchasableItem {
        let errorItem = errorItem(id: UUID(), error: error)
        purchasableItems.insert(errorItem, at: purchasableItems.startIndex)
        return errorItem
    }

    private func errorItem(id: UUID, error: PointOfSaleBarcodeScanError) -> Cart.PurchasableItem {
        Cart.PurchasableItem(
            id: id,
            title: title(for: error),
            subtitle: subtitle(for: error),
            quantity: 1,
            state: .error,
            accessibilityLabel: accessibilityLabel(for: error)
        )
    }

    private func title(for error: PointOfSaleBarcodeScanError) -> String {
        switch error {
        case .unknown(let scannedCode),
                .noParentProductForVariation(let scannedCode),
                .variationCouldNotBeConverted(let scannedCode),
                .notFound(let scannedCode),
                .loadingError(let scannedCode, _),
                .mappingError(let scannedCode, _),
                .scanTooShort(let scannedCode),
                .timedOut(let scannedCode):
            return scannedCode
        case .unsupportedProductType(_, let productName, _),
                .downloadableProduct(_, let productName):
            return productName
        case .parsingError:
            return Localization.scanFailed
        }
    }

    private func subtitle(for error: PointOfSaleBarcodeScanError) -> String {
        return error.localizedDescription
    }

    private func accessibilityLabel(for error: PointOfSaleBarcodeScanError) -> String {
        let errorDescription = error.localizedDescription
        let scannedValue = title(for: error)
        return "\(errorDescription). \(scannedValue)"
    }
}

extension PointOfSaleBarcodeScanError {
    var localizedDescription: String {
        switch self {
        case .notFound, .unknown:
            return Localization.notFound
        case .downloadableProduct, .unsupportedProductType:
            return Localization.unsupportedProductType
        case .noParentProductForVariation, .variationCouldNotBeConverted:
            return Localization.noParentProduct
        case let .loadingError(_, underlyingError), let .mappingError(_, underlyingError):
            if underlyingError.isConnectivityError {
                return Localization.noInternetConnection
            } else {
                return Localization.networkRequestFailed
            }
        case .scanTooShort:
            return Localization.barcodeTooShort
        case .timedOut:
            return Localization.incompleteScan
        case .parsingError:
            return Localization.parsingError
        }
    }

    private enum Localization {
        static let notFound = NSLocalizedString(
            "pointOfSale.barcodeScan.error.notFound",
            value: "Unknown scanned item",
            comment: "Error message shown when a scanned item is not found in the store."
        )

        static let unsupportedProductType = NSLocalizedString(
            "pointOfSale.barcodeScan.error.unsupportedProductType",
            value: "Unsupported item type",
            comment: "Error message shown when a scanned item is of an unsupported type."
        )

        static let noInternetConnection = NSLocalizedString(
            "pointOfSale.barcodeScan.error.noInternetConnection",
            value: "No internet connection",
            comment: "Error message shown when there is an internet connection error while scanning a barcode."
        )

        static let networkRequestFailed = NSLocalizedString(
            "pointOfSale.barcodeScan.error.network",
            value: "Network request failed",
            comment: "Error message shown when there is an unknown networking error while scanning a barcode."
        )

        static let noParentProduct = NSLocalizedString(
            "pointOfSale.barcodeScan.error.noParentProduct",
            value: "Parent product not found for variation",
            comment: "Error message shown when parent product is not found for a variation."
        )

        static let barcodeTooShort = NSLocalizedString(
            "pointOfSale.barcodeScan.error.barcodeTooShort",
            value: "Barcode too short",
            comment: "Error message shown when scan is too short."
        )

        static let incompleteScan = NSLocalizedString(
            "pointOfSale.barcodeScan.error.incompleteScan.2",
            value: "The scanner did not send an end-of-line character",
            comment: "Error message shown when scanner times out without sending end-of-line character."
        )

        static let parsingError = NSLocalizedString(
            "pointOfSale.barcodeScan.error.parsingError",
            value: "Couldn't read barcode",
            comment: "Error message shown when parsing barcode data fails."
        )
    }
}

private extension Cart {
    enum Localization {
        static let scanFailed = NSLocalizedString(
            "pointOfSale.barcodeScan.error.scanFailed",
            value: "Scan failed",
            comment: "Error message when scanning a barcode fails for an unknown reason, before lookup."
        )
    }
}
