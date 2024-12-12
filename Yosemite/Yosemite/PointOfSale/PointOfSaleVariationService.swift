import Foundation
import protocol Networking.Network
import class Networking.ProductVariationsRemote
import protocol Networking.ProductVariationsRemoteProtocol
import class Networking.AlamofireNetwork
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

public enum PointOfSaleVariationServiceError: Error {
    case requestFailed
    case pageOutOfRange
    case unknown
}

/// Variation provider for the Point of Sale feature
///


public final class PointOfSaleVariationService: PointOfSaleItemServiceProtocol {
    private let siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let variationService: ProductVariationsRemoteProtocol
    private let parentProduct: POSVariableProductParent

    public init(siteID: Int64, currencySettings: CurrencySettings, network: Network, parentProduct: POSVariableProductParent) {
        self.siteID = siteID
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.variationService = ProductVariationsRemote(network: network)
        self.parentProduct = parentProduct
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?,
                            parentProduct: POSVariableProductParent) {
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  network: AlamofireNetwork(credentials: credentials),
                  parentProduct: parentProduct)
    }

    public func providePointOfSaleItems(pageNumber: Int) async throws -> [any POSDisplayableItem] {
        try await variationService.fetchProductVariations(
            for: siteID,
            parentProductID: parentProduct.productID,
            pageNumber: pageNumber,
            pageSize: 25)
        .map { variation in
            POSVariation(variation: variation, currencyFormatter: currencyFormatter)
        }
    }
}

private extension POSVariation {
    init (variation: ProductVariation, currencyFormatter: CurrencyFormatter) {
        let formattedPrice = currencyFormatter.formatAmount(variation.price) ?? "-"
        self.id = UUID()
        self.name = "Variation \(variation.productVariationID) of \(variation.productID)"
        self.formattedPrice = formattedPrice
        self.price = variation.price
        self.productID = variation.productID
        self.productVariationID = variation.productVariationID
        self.productImageSource = variation.image?.src
    }
}
