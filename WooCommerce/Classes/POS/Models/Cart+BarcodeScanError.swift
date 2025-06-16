import Foundation
import enum Yosemite.PointOfSaleBarcodeScanError

extension Cart {
    mutating func updateLoadingItem(id: UUID, with error: PointOfSaleBarcodeScanError) {
        guard let index = purchasableItems.firstIndex(where: { $0.id == id }) else { return }

        purchasableItems[index] = Cart.PurchasableItem(
            id: id,
            title: title(for: error),
            subtitle: subtitle(for: error),
            quantity: 1,
            state: .error
        )
    }

    private func title(for error: PointOfSaleBarcodeScanError) -> String {
        switch error {
        case .unknown(let scannedCode),
                .noParentProductForVariation(let scannedCode),
                .variationCouldNotBeConverted(let scannedCode),
                .notFound(let scannedCode),
                .loadingError(let scannedCode, _),
                .mappingError(let scannedCode, _):
            return scannedCode
        case .unsupportedProductType(_, let productName, _),
                .downloadableProduct(_, let productName):
            return productName
        }
    }

    private func subtitle(for error: PointOfSaleBarcodeScanError) -> String {
        return error.localizedDescription
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
    }
}
