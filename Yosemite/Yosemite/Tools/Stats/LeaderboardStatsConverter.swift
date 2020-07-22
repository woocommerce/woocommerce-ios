import Foundation
import class Aztec.HTMLParser
import struct Aztec.Element

/// Helper functions to  convert a `Leaderboard` type into a `TopEearnerStat`
///
struct LeaderboardStatsConverter {

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
}
