import Foundation
import Codegen

/// A struct to decode product reports.
///
public struct ProductReport: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let totals: ProductReportTotals

    public init(totals: ProductReportTotals) {
        self.totals = totals
    }
}

/// A struct to decode product report totals.
///
public struct ProductReportTotals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let segments: [ProductReportSegment]

    public init(segments: [ProductReportSegment]) {
        self.segments = segments
    }
}

/// Segment in a product report containing product name, ID, and items sold in a time period.
///
public struct ProductReportSegment: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
    public let productID: Int64
    public let productName: String
    public let subtotals: Subtotals

    public init(productID: Int64, productName: String, subtotals: ProductReportSegment.Subtotals) {
        self.productName = productName
        self.productID = productID
        self.subtotals = subtotals
    }

    /// The public initializer.
    ///
    public init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let productID = container.failsafeDecodeIfPresent(
            targetType: Int64.self,
            forKey: .productID,
            alternativeTypes: [.string(transform: { Int64($0) ?? 0 })]) ?? 0
        let productName = (try? container.decode(String.self, forKey: .productName)) ?? ""
        let subtotals = try container.decode(Subtotals.self, forKey: .subtotals)

        self.init(productID: productID,
                  productName: productName,
                  subtotals: subtotals)
    }
}

private extension ProductReportSegment {
    enum CodingKeys: String, CodingKey {
        case productName  = "segment_label"
        case productID = "segment_id"
        case subtotals
    }
}

/// Statistics for a product in a time period.
///
public extension ProductReportSegment {
    struct Subtotals: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {
        public let itemsSold: Int

        public init(itemsSold: Int) {
            self.itemsSold = itemsSold
        }
    }
}

private extension ProductReportSegment.Subtotals {
    enum CodingKeys: String, CodingKey {
        case itemsSold  = "items_sold"
    }
}
