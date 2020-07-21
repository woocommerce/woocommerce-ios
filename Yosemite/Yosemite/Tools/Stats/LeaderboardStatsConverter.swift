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

    /// Returns the correct formatted date for `TopEarnerStats` from a date using the provided `granularity`
    /// `.hourly` granularity is not supported
    //
    static func statsDateFor(date: Date, using granularity: StatGranularity) -> String {
        switch granularity {
        case .day:
            return DateFormatter.Stats.statsDayFormatter.string(from: date)
        case .week:
            return DateFormatter.Stats.statsWeekFormatter.string(from: date)
        case .month:
            return DateFormatter.Stats.statsMonthFormatter.string(from: date)
        case .year:
            return DateFormatter.Stats.statsYearFormatter.string(from: date)
        }
    }
}
