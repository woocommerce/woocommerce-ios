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

    func itemForProductOrVariation(_ productOrVariation: POSProduct,
                                   scannedCode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        let items: [POSItem]

        guard productOrVariation.downloadable == false else {
            throw .downloadableProduct(scannedCode: scannedCode, productName: productOrVariation.name)
        }

        switch productOrVariation.productType {
        case .simple:
            let product = productOrVariation
            items = itemMapper.mapProductsToPOSItems(products: [product])
        case .custom("variation"):
            let variation = try productOrVariation.toProductVariation(scannedCode: scannedCode)
            let variableProduct = try await parentProductForVariation(variation, scannedCode: scannedCode)
            items = itemMapper.mapVariationsToPOSItems(variations: [variation], parentProduct: variableProduct)
        default:
            throw .unsupportedProductType(scannedCode: scannedCode,
                                          productName: productOrVariation.name,
                                          productType: productOrVariation.productType)
        }

        guard let item = items.first else {
            throw .unknown(scannedCode: scannedCode)
        }
        return item
    }

    private func parentProductForVariation(_ variation: POSProductVariation,
                                           scannedCode: String) async throws(PointOfSaleBarcodeScanError) -> POSVariableParentProduct {
        guard variation.productID != 0 else {
            throw .noParentProductForVariation(scannedCode: scannedCode)
        }

        let parentProduct = try await loadParentProduct(variation, scannedCode: scannedCode)
        let mappedProducts = itemMapper.mapProductsToPOSItems(products: [parentProduct])

        guard let mappedProduct = mappedProducts.first,
              case .variableParentProduct(let variableProduct) = mappedProduct else {
            throw .variationCouldNotBeConverted(scannedCode: scannedCode)
        }
        return variableProduct
    }

    private func loadParentProduct(_ variation: POSProductVariation,
                                   scannedCode: String) async throws(PointOfSaleBarcodeScanError) -> POSProduct {
        do {
            return try await productsRemote.loadPOSProduct(for: variation.siteID,
                                                           productID: variation.productID)
        } catch {
            switch ProductLoadError(underlyingError: error) {
            case .notFound:
                throw .noParentProductForVariation(scannedCode: scannedCode)
            default:
                throw .loadingError(scannedCode: scannedCode, underlyingError: error)
            }
        }
    }
}


private extension POSProduct {
    func toProductVariation(scannedCode: String) throws(PointOfSaleBarcodeScanError) -> POSProductVariation {
        do {
            return POSProductVariation(
                siteID: siteID,
                productID: parentID,
                productVariationID: productID,
                attributes: try attributes.compactMap { try $0.toProductVariationAttribute() },
                image: images.first,
                fullDescription: fullDescription,
                sku: sku,
                globalUniqueID: globalUniqueID,
                typeKey: productTypeKey,
                price: price,
                downloadable: downloadable,
                manageStock: manageStock,
                stockQuantity: stockQuantity,
                stockStatusKey: stockStatusKey
            )
        } catch {
            throw .mappingError(scannedCode: scannedCode, underlyingError: error)
        }
    }
}
