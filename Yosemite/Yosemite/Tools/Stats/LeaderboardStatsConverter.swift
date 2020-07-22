import Foundation
import class Aztec.HTMLParser
import struct Aztec.Element

/// Helper functions to  convert a `Leaderboard` type into a `TopEearnerStat`
///
struct LeaderboardStatsConverter {

    /// Returns the ids of the products associated with a top products leaderboar
    ///
    static func topProductsIDs(from topProducts: Leaderboard) -> [Int64] {
        return topProducts.rows.compactMap {
            LeaderboardStatsConverter.infeerProductID(fromHTMLString: $0.subject.display)
        }
    }

    /// Indicates what products are missing from a leaderboard in an array of stored products
    ///
    static func missingProductsIDs(from topProducts: Leaderboard, in storedProducts: [Product]) -> [Int64] {

        // Get the top products IDs
        let topProductsIDs = Self.topProductsIDs(from: topProducts)

        // Get the stored products IDs
        let storedProductsIDs = storedProducts.map { $0.productID }

        // Figure out which top products IDs are missing from store products IDs
        let missingIDs = Set(topProductsIDs).subtracting(storedProductsIDs)
        return Array(missingIDs)
    }

    /// Converts a the`leaderboard rows(top products)` into an array `TopEarnerStatsItem` using an array of stored products to match
    ///
    static func topEearnerStatItems(from topProducts: Leaderboard, using storedProducts: [Product]) -> [TopEarnerStatsItem] {
        return topProducts.rows.compactMap {
            Self.topEearnerStatItem(from: $0, using: storedProducts)
        }
    }
}

/// MARK: Private helpers
private extension LeaderboardStatsConverter {

    /// Infeers a product-id from an specific html string type
    /// A valid html is an `a` tag with an `href` that includes the `product_id` in a query parameter named `products`
    /// EG:  `<a href='https://store.com?products=9'>Product</a>`
    ///
    static func infeerProductID(fromHTMLString html: String) -> Int64? {

        // Parse and extract the `products` parameter out the the html using `Aztec parser` and `URLComponents`
        let parsed = HTMLParser().parse(html)
        guard let a = parsed.firstChild(ofType: .a),
            let href = a.attribute(ofType: .href)?.value.toString(),
            let queryItems = URLComponents(string: href)?.queryItems,
            let productItemValue = queryItems.first(where: { $0.name == "products"} )?.value else {
                return nil
        }

        // Try to convert the `productID` to an `Int`
        return Int64(productItemValue)
    }

    /// Converts a `leaderboard row(top product)` into a `TopEarnerStatsItem` using an array of stored products to match
    ///
    static func topEearnerStatItem(from topProduct: LeaderboardRow, using storedProducts: [Product]) -> TopEarnerStatsItem? {

        // Match the product that corresponds to the leaderboard row(top product)
        guard let productID = LeaderboardStatsConverter.infeerProductID(fromHTMLString: topProduct.subject.display),
            let product = storedProducts.first(where: { $0.productID == productID }) else {
                return nil
        }

        // Create the stat item using the two sources of information
        return TopEarnerStatsItem(productID: productID,
                                  productName: product.name,
                                  quantity: topProduct.quantity.value,
                                  price: Double(product.price) ?? 0.0,
                                  total: topProduct.total.value,
                                  currency: "USD", // TODO: Sort out currency
                                  imageUrl: product.images.first?.src)
    }
}
