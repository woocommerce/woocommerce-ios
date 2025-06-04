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
}

/// Service for handling barcode scanning in Point of Sale
public final class PointOfSaleBarcodeScanService: PointOfSaleBarcodeScanServiceProtocol {
    private let productsRemote: ProductsRemoteProtocol
    private let currencyFormatter: CurrencyFormatter
    private let siteID: Int64
    private let itemMapper: PointOfSaleItemMapper

    init (siteID: Int64,
          productsRemote: ProductsRemoteProtocol,
          currencySettings: CurrencySettings) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.itemMapper = PointOfSaleItemMapper(currencyFormatter: currencyFormatter)
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

            let items = itemMapper.mapProductsToPOSItems(products: [product])

            guard let item = items.first else {
                throw PointOfSaleBarcodeScanError.unknown
            }

            return item
        } catch {
            throw PointOfSaleBarcodeScanError.unknown
        }
    }
}
