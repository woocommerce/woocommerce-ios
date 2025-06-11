import Foundation
import protocol Networking.ProductsRemoteProtocol
import class WooFoundation.CurrencySettings

struct POSProductOrVariationResolver {
    private let productsRemote: ProductsRemoteProtocol
    private let itemMapper: PointOfSaleItemMapperProtocol

    init (productsRemote: ProductsRemoteProtocol,
          currencySettings: CurrencySettings,
          itemMapper: PointOfSaleItemMapperProtocol? = nil) {
        self.productsRemote = productsRemote
        self.itemMapper = itemMapper ?? PointOfSaleItemMapper(currencySettings: currencySettings)
    }

    func itemForProductOrVariation(_ productOrVariation: POSProduct) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        let items: [POSItem]

        guard productOrVariation.downloadable == false else {
            throw .downloadableProduct
        }

        switch productOrVariation.productType {
        case .simple:
            let product = productOrVariation
            items = itemMapper.mapProductsToPOSItems(products: [product])
        case .custom("variation"):
            let variation = try productOrVariation.toProductVariation()
            let variableProduct = try await parentProductForVariation(variation)
            items = itemMapper.mapVariationsToPOSItems(variations: [variation], parentProduct: variableProduct)
        default:
            throw .unsupportedProductType
        }

        guard let item = items.first else {
            throw .unknown
        }
        return item
    }

    private func parentProductForVariation(_ variation: POSProductVariation) async throws(PointOfSaleBarcodeScanError) -> POSVariableParentProduct {
        guard variation.productID != 0 else {
            throw .noParentProductForVariation
        }

        let parentProduct = try await loadParentProduct(variation)
        let mappedProducts = itemMapper.mapProductsToPOSItems(products: [parentProduct])

        guard let mappedProduct = mappedProducts.first,
              case .variableParentProduct(let variableProduct) = mappedProduct else {
            throw .variationCouldNotBeConverted
        }
        return variableProduct
    }

    private func loadParentProduct(_ variation: POSProductVariation) async throws(PointOfSaleBarcodeScanError) -> POSProduct {
        do {
            return try await productsRemote.loadPOSProduct(for: variation.siteID,
                                                           productID: variation.productID)
        } catch {
            throw .loadingError(underlyingError: error)
        }
    }
}


private extension POSProduct {
    func toProductVariation() throws(PointOfSaleBarcodeScanError) -> POSProductVariation {
        do {
            return POSProductVariation(
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
                stockStatusKey: stockStatusKey
            )
        } catch {
            throw .mappingError(underlyingError: error)
        }
    }
}
