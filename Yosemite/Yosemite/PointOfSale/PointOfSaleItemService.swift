import Foundation
import protocol Networking.Network
import protocol Networking.ProductVariationsRemoteProtocol
import class Networking.ProductsRemote
import class Networking.ProductVariationsRemote
import class Networking.CouponsRemote
import class Networking.AlamofireNetwork
import enum Alamofire.AFError
import class WooFoundation.CurrencyFormatter
import class WooFoundation.CurrencySettings

public enum PointOfSaleItemServiceError: Error, Equatable {
    case requestFailed
    case requestCancelled
    case unknown
}

/// Product provider for the Point of Sale feature
///
public final class PointOfSaleItemService: PointOfSaleItemServiceProtocol {
    private var siteID: Int64
    private let currencyFormatter: CurrencyFormatter
    private let productsRemote: ProductsRemote
    private let variationRemote: ProductVariationsRemoteProtocol
    private let couponsRemote: CouponsRemote

    public init(siteID: Int64, currencySettings: CurrencySettings, network: Network) {
        self.siteID = siteID
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
        self.productsRemote = ProductsRemote(network: network)
        self.variationRemote = ProductVariationsRemote(network: network)
        self.couponsRemote = CouponsRemote(network: network)
    }

    public convenience init(siteID: Int64,
                            currencySettings: CurrencySettings,
                            credentials: Credentials?) {
        self.init(siteID: siteID,
                  currencySettings: currencySettings,
                  network: AlamofireNetwork(credentials: credentials))
    }

    public func providePointOfSaleCoupons() async throws -> PagedItems<POSItem> {
        let coupons = try await couponsRemote.loadAllCouponsAsync(for: siteID)
        return .init(items: mapCouponsToPOSItems(coupons: coupons), hasMorePages: false)
    }

    /// Provides a list of products for the Point of Sale, by fetching simple products from the remote, applying any eligibility criteria,
    /// and maps them to POSItem type.
    ///
    /// - pageNumber: Number of the page that should be retrieved. If none given, defaults to 1
    ///
    public func providePointOfSaleItems(pageNumber: Int = 1) async throws -> PagedItems<POSItem> {
        let productTypes: [ProductType] = [.simple, .variable]
        do {
            let pagedProducts = try await productsRemote.loadProductsForPointOfSale(for: siteID, productTypes: productTypes, pageNumber: pageNumber)
            let products = pagedProducts.items

            if pageNumber != 1 && products.count == 0 {
                return .init(items: [], hasMorePages: false)
            }

            return .init(items: mapProductsToPOSItems(products: products), hasMorePages: pagedProducts.hasMorePages)
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleItemServiceError.requestCancelled
        }
    }

    public func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct, pageNumber: Int) async throws -> PagedItems<POSItem> {
        do {
            let pagedVariations = try await variationRemote
                .loadVariationsForPointOfSale(for: siteID,
                                              parentProductID: parentProduct.productID,
                                              pageNumber: pageNumber)
            let variations = pagedVariations.items
            // Remove this when WC version 9.7 has significant adoption in POS stores.
                .filter { !$0.downloadable }
            return .init(
                items: variations.compactMap({ variation in
                    let variationName = ProductVariationFormatter().generateNameWithAttributeNames(
                        for: variation,
                        from: parentProduct.allAttributes,
                        separator: ", "
                    )
                    return POSItem
                        .variation(.init(id: UUID(),
                                         name: variationName,
                                         formattedPrice: formatPrice(variation.price),
                                         price: variation.price,
                                         productImageSource: variation.image?.src,
                                         productID: variation.productID,
                                         variationID: variation.productVariationID,
                                         parentProductName: parentProduct.name))
                }),
                hasMorePages: pagedVariations.hasMorePages
            )
        } catch AFError.explicitlyCancelled {
            throw PointOfSaleItemServiceError.requestCancelled
        }
    }

    private func mapCouponsToPOSItems(coupons: [Coupon]) -> [POSItem] {
        return coupons.compactMap { coupon in
                .coupon(POSCoupon(id: UUID(), couponID: coupon.couponID, code: coupon.code))
        }
    }

    // Maps result to POSItem, and populate the output with:
    // - Formatted price based on store's currency settings.
    // - Product thumbnail, if any.
    private func mapProductsToPOSItems(products: [Product]) -> [POSItem] {
        return products.compactMap { product in
            let thumbnailSource = product.images.first?.src

            switch product.productType {
                case .simple:
                    return .simpleProduct(POSSimpleProduct(id: UUID(),
                                                           name: product.name,
                                                           formattedPrice: formatPrice(product.price),
                                                           productImageSource: thumbnailSource,
                                                           productID: product.productID,
                                                           price: product.price))
                case .variable:
                    return .variableParentProduct(POSVariableParentProduct(
                        id: UUID(),
                        name: product.name,
                        productImageSource: thumbnailSource,
                        productID: product.productID,
                        allAttributes: product.attributesForVariations
                    ))
                default:
                    return nil
            }
        }
    }

    private func formatPrice(_ price: String) -> String {
        let zeroOrPlaceholder = currencyFormatter.formatAmount("0") ?? "-"
        return currencyFormatter.formatAmount(price) ?? zeroOrPlaceholder
    }
}
