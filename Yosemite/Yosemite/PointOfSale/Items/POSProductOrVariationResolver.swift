import Foundation
import protocol Networking.ProductsRemoteProtocol
import class WooFoundation.CurrencySettings

struct POSProductOrVariationResolver {
    private let productsRemote: ProductsRemoteProtocol
    private let itemMapper: PointOfSaleItemMapper

    init (productsRemote: ProductsRemoteProtocol,
          currencySettings: CurrencySettings) {
        self.productsRemote = productsRemote
        self.itemMapper = PointOfSaleItemMapper(currencySettings: currencySettings)
    }

    func itemForProductOrVariation(_ productOrVariation: POSProduct) async throws -> POSItem {
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

        let parentProduct = try await productsRemote.fetchPOSProduct(for: variation.siteID,
                                                                     productID: variation.productID)
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
