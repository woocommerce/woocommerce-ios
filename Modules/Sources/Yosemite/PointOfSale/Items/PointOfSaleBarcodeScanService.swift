import Foundation
import protocol Networking.ProductsRemoteProtocol
import class Networking.ProductsRemote
import class WooFoundation.CurrencySettings
import class Networking.AlamofireNetwork
import enum Networking.NetworkError

public protocol PointOfSaleBarcodeScanServiceProtocol {
    func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem
}

public enum PointOfSaleBarcodeScanError: Error {
    case unknown(scannedCode: String)
    case noParentProductForVariation(scannedCode: String)
    case variationCouldNotBeConverted(scannedCode: String)
    case unsupportedProductType(scannedCode: String, productName: String, productType: ProductType)
    case downloadableProduct(scannedCode: String, productName: String)
    case notFound(scannedCode: String)
    case loadingError(scannedCode: String, underlyingError: Error)
    case mappingError(scannedCode: String, underlyingError: Error)
    case scanTooShort(scannedCode: String)
    case timedOut(scannedCode: String)
    case parsingError(underlyingError: Error)
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
    public func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        let productOrVariation = try await loadPOSProduct(barcode: barcode)
        return try await itemResolver.itemForProductOrVariation(productOrVariation, scannedCode: barcode)
    }

    private func loadPOSProduct(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSProduct {
        do {
            return try await productsRemote.loadPOSProductByGlobalUniqueIdentifier(for: siteID,
                                                                                   globalUniqueID: barcode)
        } catch NetworkError.notFound {
            throw .notFound(scannedCode: barcode)
        } catch {
            throw .loadingError(scannedCode: barcode, underlyingError: error)
        }
    }
}
