import Foundation
import protocol Storage.GRDBManagerProtocol
import Storage
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
    /// - Parameter barcode: The barcode string from a scan (global unique identifier or SKU)
    /// - Returns: A POSItem if found, or throws an error
    public func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        // Search for product or variation by barcode
        // Try globalUniqueID first, then fall back to SKU
        do {
            if let product = try searchProductByGlobalUniqueID(barcode) {
                return try convertProductToItem(product, scannedCode: barcode)
            }

            if let variationAndParent = try searchVariationByGlobalUniqueID(barcode) {
                return try await convertVariationToItem(variationAndParent.variation, parentProduct: variationAndParent.parentProduct, scannedCode: barcode)
            }

            if let product = try searchProductBySKU(barcode) {
                return try convertProductToItem(product, scannedCode: barcode)
            }

            if let variationAndParent = try searchVariationBySKU(barcode) {
                return try await convertVariationToItem(variationAndParent.variation, parentProduct: variationAndParent.parentProduct, scannedCode: barcode)
            }

            // No match found
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

    private func searchProductBySKU(_ sku: String) throws -> PersistedProduct? {
        try grdbManager.databaseConnection.read { db in
            try PersistedProduct.posProductBySKU(siteID: siteID, sku: sku).fetchOne(db)
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
                return nil
            }
            return (variation, parentProduct)
        }
    }

    private func searchVariationBySKU(_ sku: String) throws -> (variation: PersistedProductVariation, parentProduct: PersistedProduct)? {
        try grdbManager.databaseConnection.read { db in
            guard let variation = try PersistedProductVariation.posVariationBySKU(siteID: siteID, sku: sku).fetchOne(db) else {
                return nil
            }
            // Fetch parent product using the relationship
            guard let parentProduct = try variation.request(for: PersistedProductVariation.parentProduct).fetchOne(db) else {
                return nil
            }
            return (variation, parentProduct)
        }
    }

    // MARK: - Conversion to POSItem

    private func convertProductToItem(_ persistedProduct: PersistedProduct, scannedCode: String) throws(PointOfSaleBarcodeScanError) -> POSItem {
        do {
            let posProduct = try persistedProduct.toPOSProduct(db: grdbManager.databaseConnection)

            // Validate product is not downloadable (should already be filtered by query, but double-check)
            guard !posProduct.downloadable else {
                throw PointOfSaleBarcodeScanError.downloadableProduct(scannedCode: scannedCode, productName: posProduct.name)
            }

            // Validate product type
            guard [.simple, .variable].contains(posProduct.productType) else {
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

    private func convertVariationToItem(_ persistedVariation: PersistedProductVariation, parentProduct: PersistedProduct, scannedCode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        do {
            // Validate variation is not downloadable (should already be filtered by query, but double-check)
            guard !persistedVariation.downloadable else {
                // We don't have the product name for variations, so use a generic message
                throw PointOfSaleBarcodeScanError.downloadableProduct(scannedCode: scannedCode, productName: "Product variation")
            }

            // Convert both variation and parent to POS models
            let posVariation = try persistedVariation.toPOSProductVariation(db: grdbManager.databaseConnection)
            let parentPOSProduct = try parentProduct.toPOSProduct(db: grdbManager.databaseConnection)

            // Map parent to POSVariableParentProduct
            let mappedParents = itemMapper.mapProductsToPOSItems(products: [parentPOSProduct])
            guard let mappedParent = mappedParents.first,
                  case .variableParentProduct(let variableParentProduct) = mappedParent else {
                throw PointOfSaleBarcodeScanError.variationCouldNotBeConverted(scannedCode: scannedCode)
            }

            // Convert to POSItem
            let items = itemMapper.mapVariationsToPOSItems(variations: [posVariation], parentProduct: variableParentProduct)
            guard let item = items.first else {
                throw PointOfSaleBarcodeScanError.variationCouldNotBeConverted(scannedCode: scannedCode)
            }

            return item
        } catch let error as PointOfSaleBarcodeScanError {
            throw error
        } catch {
            throw PointOfSaleBarcodeScanError.mappingError(scannedCode: scannedCode, underlyingError: error)
        }
    }
}
