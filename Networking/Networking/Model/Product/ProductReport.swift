import Foundation
import Codegen

/// An internal struct to decode product reports.
///
struct ProductReport: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    let totals: ProductReportTotals

    init(totals: ProductReportTotals) {
        self.totals = totals
    }
}

/// An internal struct to decode product report totals.
///
struct ProductReportTotals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    let segments: [ProductReportSegment]

    init(segments: [ProductReportSegment]) {
        self.segments = segments
    }
}

/// Segment in a product report containing product name, ID, and items sold in a time period.
/// 
public struct ProductReportSegment: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let productName: String
    public let productID: Int64
    public let subtotals: Subtotals

    public init(productName: String, productID: Int64, subtotals: ProductReportSegment.Subtotals) {
        self.productName = productName
        self.productID = productID
        self.subtotals = subtotals
    }
}

/// Statistics for a product in a time period.
///
public extension ProductReportSegment {
    struct Subtotals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
        public let itemsSold: Int
        public let netRevenue: Double
        public let ordersCount: Int

        public init(itemsSold: Int, netRevenue: Double, ordersCount: Int) {
            self.itemsSold = itemsSold
            self.netRevenue = netRevenue
            self.ordersCount = ordersCount
        }
    }
}
