import Foundation
import protocol Networking.ProductsRemoteProtocol
import class Networking.ProductsRemote
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
    private let itemResolver: POSProductOrVariationResolver

    init (siteID: Int64,
          productsRemote: ProductsRemoteProtocol,
          currencySettings: CurrencySettings) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.itemResolver = POSProductOrVariationResolver(productsRemote: productsRemote,
                                                          currencySettings: currencySettings)
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
            let productOrVariation = try await productsRemote.loadPOSProductByGlobalUniqueIdentifier(for: siteID,
                                                                                                      globalUniqueID: barcode)
            return try await itemResolver.itemForProductOrVariation(productOrVariation)
        } catch {
            throw PointOfSaleBarcodeScanError.unknown
        }
    }
}
