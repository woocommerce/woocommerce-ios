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
public final class PointOfSaleVariationService {
    private let siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let variationService: ProductVariationsRemoteProtocol

    public init(siteID: Int64, currencySettings: CurrencySettings, network: Network) {
        self.siteID = siteID
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.variationService = ProductVariationsRemote(network: network)
    }

    public func providePointOfSaleItems(parentProductID: Int64, pageNumber: Int) async throws -> [POSItem] {
        return try await variationService.fetchProductVariations(
            for: siteID,
            parentProductID: parentProductID,
            pageNumber: pageNumber,
            pageSize: 25)
        .map { variation in
                .variation(POSVariation(variation: variation, currencyFormatter: currencyFormatter))
        }
    }
}

private extension POSVariation {
    init (variation: ProductVariation, currencyFormatter: CurrencyFormatter) {
        let formattedPrice = currencyFormatter.formatAmount(variation.price) ?? "-"
        self.id = UUID()
        self.name = "Variation \(variation.productVariationID) of \(variation.productID)"
        self.formattedPrice = formattedPrice
        self.productID = variation.productID
        self.variationID = variation.productVariationID
        self.productImageSource = variation.image?.src
    }
}
