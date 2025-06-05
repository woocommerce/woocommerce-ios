import Foundation
import protocol Networking.ProductsRemoteProtocol
import class Networking.ProductsRemote
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import class Networking.AlamofireNetwork

public protocol PointOfSaleBarcodeScanServiceProtocol {
    func getItem(barcode: String) async throws -> POSItem
}

public enum PointOfSaleBarcodeScanError: Error, Equatable {
    case unknown
    case noParentProductForVariation
    case variationCouldNotBeConverted
}

/// Service for handling barcode scanning in Point of Sale
public final class PointOfSaleBarcodeScanService: PointOfSaleBarcodeScanServiceProtocol {
    private let productsRemote: ProductsRemoteProtocol
    private let siteID: Int64
    private let itemMapper: PointOfSaleItemMapper

    init (siteID: Int64,
          productsRemote: ProductsRemoteProtocol,
          currencySettings: CurrencySettings) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.itemMapper = PointOfSaleItemMapper(currencySettings: currencySettings)
    }

    public convenience init(siteID: Int64,
                            credentials: Credentials?,
                            currencySettings: CurrencySettings) {
        let network = AlamofireNetwork(credentials: credentials)
        self.init(siteID: siteID,
                  productsRemote: ProductsRemote(network: network),
                  currencySettings: currencySettings)
    }

    /// Looks up a POSItem using a barcode scan string
    /// - Parameter barcode: The barcode string from a scan (global unique identifier)
    /// - Returns: A POSItem if found, or throws an error
    public func getItem(barcode: String) async throws -> POSItem {
        do {
            let productOrVariation = try await productsRemote.fetchPOSProductByGlobalUniqueIdentifier(for: siteID,
                                                                                                      globalUniqueID: barcode)
            return try await itemForScannedBarcodeProduct(productOrVariation)
        } catch {
            throw PointOfSaleBarcodeScanError.unknown
        }
    }

    private func itemForScannedBarcodeProduct(_ productOrVariation: POSProduct) async throws -> POSItem {
        let items: [POSItem]
        switch productOrVariation.productType {
        case .simple:
            let product = productOrVariation
            items = itemMapper.mapProductsToPOSItems(products: [product])
        case .custom("variation"):
            let variation = try productOrVariation.toProductVariation()
            let variableProduct = try await parentProductForVariation(variation)
            items = itemMapper.mapVariationsToPOSItems(variations: [variation], parentProduct: variableProduct)
        default:
            throw PointOfSaleBarcodeScanError.unknown
        }

        guard let item = items.first else {
            throw PointOfSaleBarcodeScanError.unknown
        }
        return item
    }

    private func parentProductForVariation(_ variation: POSProductVariation) async throws -> POSVariableParentProduct {
        guard variation.productID != 0 else {
            throw PointOfSaleBarcodeScanError.noParentProductForVariation
        }

        let parentProduct = try await productsRemote.fetchPOSProduct(for: siteID, productID: variation.productID)
        let mappedProducts = itemMapper.mapProductsToPOSItems(products: [parentProduct])

        guard let mappedProduct = mappedProducts.first,
              case .variableParentProduct(let variableProduct) = mappedProduct else {
            throw PointOfSaleBarcodeScanError.variationCouldNotBeConverted
        }
        return variableProduct
    }
}


private extension POSProduct {
    func toProductVariation() throws -> POSProductVariation {
        POSProductVariation(
            siteID: siteID,
            productID: parentID,
            productVariationID: productID,
            attributes: try attributes.compactMap { try $0.toProductVariationAttribute() },
            image: images.first,
            sku: sku,
            globalUniqueID: globalUniqueID,
            price: price,
            regularPrice: regularPrice,
            salePrice: salePrice,
            onSale: onSale,
            downloadable: downloadable,
            manageStock: manageStock,
            stockQuantity: stockQuantity,
            stockStatusKey: stockStatusKey)
    }
}
