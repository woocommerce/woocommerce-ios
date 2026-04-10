import Foundation
import protocol Networking.ProductsRemoteProtocol
import class Networking.ProductsRemote
import enum Networking.ProductStatus
import class WooFoundation.CurrencySettings
import class Networking.AlamofireNetwork
import enum Networking.NetworkError
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

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
    private let posProductsOnly: Bool

    init (siteID: Int64,
          productsRemote: ProductsRemoteProtocol,
          currencySettings: CurrencySettings,
          posProductsOnly: Bool = false) {
        self.siteID = siteID
        self.productsRemote = productsRemote
        self.posProductsOnly = posProductsOnly
        self.itemResolver = POSProductOrVariationResolver(productsRemote: productsRemote,
                                                          currencySettings: currencySettings,
                                                          posProductsOnly: posProductsOnly)
    }

    public convenience init(siteID: Int64,
                            credentials: Credentials?,
                            selectedSite: AnyPublisher<JetpackSite?, Never>,
                            appPasswordSupportState: AnyPublisher<Bool, Never>,
                            currencySettings: CurrencySettings,
                            posProductsOnly: Bool = false) {
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.init(siteID: siteID,
                  productsRemote: ProductsRemote(network: network),
                  currencySettings: currencySettings,
                  posProductsOnly: posProductsOnly)
    }

    /// Looks up a POSItem using a barcode scan string
    /// - Parameter barcode: The barcode string from a scan (global unique identifier)
    /// - Returns: A POSItem if found, or throws an error
    public func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        let productOrVariation = try await loadPOSProduct(barcode: barcode)

        // Validate that the product status is allowed for POS
        try validateProductStatus(productOrVariation, scannedCode: barcode)

        return try await itemResolver.itemForProductOrVariation(productOrVariation, scannedCode: barcode)
    }

    private func loadPOSProduct(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSProduct {
        do {
            return try await productsRemote.loadPOSProductByGlobalUniqueIdentifier(for: siteID,
                                                                                   globalUniqueID: barcode,
                                                                                   posProductsOnly: posProductsOnly)
        } catch NetworkError.notFound {
            throw .notFound(scannedCode: barcode)
        } catch {
            throw .loadingError(scannedCode: barcode, underlyingError: error)
        }
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
