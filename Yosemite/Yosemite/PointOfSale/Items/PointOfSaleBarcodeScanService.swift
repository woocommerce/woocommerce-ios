import Foundation
import protocol Networking.ProductsRemoteProtocol
import class Networking.ProductsRemote
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings
import class Networking.AlamofireNetwork

public enum PointOfSaleBarcodeScanError: Error, Equatable {
    case unknown
}

/// Service for handling barcode scanning in Point of Sale
public final class PointOfSaleBarcodeScanService {
    private let productsRemote: ProductsRemoteProtocol
    private let currencyFormatter: CurrencyFormatter
    private let siteID: Int64

    init (siteID: Int64,
          productsRemote: ProductsRemoteProtocol,
          currencySettings: CurrencySettings) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
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
            let product = try await productsRemote.fetchPOSProductByGlobalUniqueIdentifier(for: siteID, globalUniqueID: barcode)

            guard product.productType == .simple else {
                throw PointOfSaleBarcodeScanError.unknown
            }

            // Convert POSProduct to POSSimpleProduct
            let simpleProduct = POSSimpleProduct(
                id: UUID(),
                name: product.name,
                formattedPrice: currencyFormatter.formatAmount(product.price) ?? "",
                productImageSource: product.images.first?.src,
                productID: product.productID,
                price: product.price,
                manageStock: product.manageStock,
                stockQuantity: product.stockQuantity,
                stockStatusKey: product.stockStatusKey
            )

            return .simpleProduct(simpleProduct)
        } catch {
            throw PointOfSaleBarcodeScanError.unknown
        }
    }
}
