import Foundation
import protocol Storage.GRDBManagerProtocol
import enum Networking.ProductStatus
import class WooFoundation.CurrencySettings

/// Service for handling barcode scanning using local GRDB catalog
public final class PointOfSaleLocalBarcodeScanService: PointOfSaleBarcodeScanServiceProtocol {
    private let grdbManager: GRDBManagerProtocol
    private let siteID: Int64
    private let itemMapper: PointOfSaleItemMapperProtocol

    public init(siteID: Int64,
                grdbManager: GRDBManagerProtocol,
                currencySettings: CurrencySettings,
                itemMapper: PointOfSaleItemMapperProtocol? = nil) {
        self.siteID = siteID
        self.grdbManager = grdbManager
        self.itemMapper = itemMapper ?? PointOfSaleItemMapper(currencySettings: currencySettings)
    }

    /// Looks up a POSItem using a barcode scan string from the local GRDB catalog
    /// - Parameter barcode: The barcode string from a scan (global unique identifier)
    /// - Returns: A POSItem if found, or throws an error
    public func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        do {
            if let product = try searchProductByGlobalUniqueID(barcode) {
                return try convertProductToItem(product, scannedCode: barcode)
            }

            if let variationAndParent = try searchVariationByGlobalUniqueID(barcode) {
                return try convertVariationToItem(variationAndParent.variation, parentProduct: variationAndParent.parentProduct, scannedCode: barcode)
            }

            throw PointOfSaleBarcodeScanError.notFound(scannedCode: barcode)
        } catch let error as PointOfSaleBarcodeScanError {
            throw error
        } catch {
            throw PointOfSaleBarcodeScanError.loadingError(scannedCode: barcode, underlyingError: error)
        }
    }

    // MARK: - Product Search

    private func searchProductByGlobalUniqueID(_ globalUniqueID: String) throws -> PersistedProduct? {
        try grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductByGlobalUniqueID(siteID: siteID, globalUniqueID: globalUniqueID).fetchOne(db)
        }
    }

    // MARK: - Variation Search

    private func searchVariationByGlobalUniqueID(_ globalUniqueID: String) throws -> (variation: PersistedProductVariation, parentProduct: PersistedProduct)? {
        try grdbManager.databaseConnection.read { db in
            guard let variation = try PersistedProductVariation.posVariationByGlobalUniqueID(siteID: siteID, globalUniqueID: globalUniqueID).fetchOne(db) else {
                return nil
            }
            // Fetch parent product using the relationship
            guard let parentProduct = try variation.request(for: PersistedProductVariation.parentProduct).fetchOne(db) else {
                throw PointOfSaleBarcodeScanError.noParentProductForVariation(scannedCode: globalUniqueID)
            }
            return (variation, parentProduct)
        }
    }

    // MARK: - Conversion to POSItem

    private func convertProductToItem(_ persistedProduct: PersistedProduct, scannedCode: String) throws(PointOfSaleBarcodeScanError) -> POSItem {
        do {
            let posProduct = try persistedProduct.toPOSProduct(db: grdbManager.databaseConnection)

            // Validate that the product status is allowed for POS
            try validateProductStatus(posProduct, scannedCode: scannedCode)

            guard !posProduct.downloadable else {
                throw PointOfSaleBarcodeScanError.downloadableProduct(scannedCode: scannedCode, productName: posProduct.name)
            }

            // Validate product type - only simple products can be scanned directly
            // Variable parent products cannot be added to cart (only their variations can)
            guard posProduct.productType == .simple else {
                throw PointOfSaleBarcodeScanError.unsupportedProductType(
                    scannedCode: scannedCode,
                    productName: posProduct.name,
                    productType: posProduct.productType
                )
            }

            // Convert to POSItem
            let items = itemMapper.mapProductsToPOSItems(products: [posProduct])
            guard let item = items.first else {
                throw PointOfSaleBarcodeScanError.unknown(scannedCode: scannedCode)
            }

            return item
        } catch let error as PointOfSaleBarcodeScanError {
            throw error
        } catch {
            throw PointOfSaleBarcodeScanError.mappingError(scannedCode: scannedCode, underlyingError: error)
        }
    }

    private func convertVariationToItem(_ persistedVariation: PersistedProductVariation,
                                        parentProduct: PersistedProduct,
                                        scannedCode: String) throws(PointOfSaleBarcodeScanError) -> POSItem {
        do {
            // Convert both variation and parent to POS models
            let posVariation = try persistedVariation.toPOSProductVariation(db: grdbManager.databaseConnection)
            let parentPOSProduct = try parentProduct.toPOSProduct(db: grdbManager.databaseConnection)

            // Validate that the parent product status is allowed for POS
            try validateProductStatus(parentPOSProduct, scannedCode: scannedCode)

            // Map to POSItem
            guard let mappedParent = itemMapper.mapProductsToPOSItems(products: [parentPOSProduct]).first,
                  case .variableParentProduct(let variableParentProduct) = mappedParent,
                  let item = itemMapper.mapVariationsToPOSItems(variations: [posVariation], parentProduct: variableParentProduct).first else {
                throw PointOfSaleBarcodeScanError.variationCouldNotBeConverted(scannedCode: scannedCode)
            }

            guard !persistedVariation.downloadable else {
                throw PointOfSaleBarcodeScanError.downloadableProduct(scannedCode: scannedCode,
                                                                      productName: variationName(for: item))
            }

            return item
        } catch let error as PointOfSaleBarcodeScanError {
            throw error
        } catch {
            throw PointOfSaleBarcodeScanError.mappingError(scannedCode: scannedCode, underlyingError: error)
        }
    }

    private func variationName(for item: POSItem) -> String {
        guard case .variation(let posVariation) = item else {
            return Localization.unknownVariationName
        }
        return posVariation.name
    }

    /// Validates that the product status is allowed for POS
    /// Throws notFound error if product has a status that should be excluded from POS
    private func validateProductStatus(_ product: POSProduct, scannedCode: String) throws(PointOfSaleBarcodeScanError) {
        let excludedStatuses: [ProductStatus] = [.trash, .draft, .pending, .privateStatus]
        if excludedStatuses.contains(product.productStatus) {
            throw .notFound(scannedCode: scannedCode)
        }
    }
}

private extension PointOfSaleLocalBarcodeScanService {
    enum Localization {
        static let unknownVariationName = NSLocalizedString(
            "pointOfSale.barcodeScanning.unresolved.variation.name",
            value: "Unknown",
            comment: "A placeholder name when we can't determine the name of a variation for an error message")
    }
}
