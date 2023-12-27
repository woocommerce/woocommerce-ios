import Foundation
import Codegen

/// Impressions forecast for a Blaze campaign
///
public struct BlazeImpressions: Decodable, GeneratedFakeable {

    /// Minimum forecasted impressions a Blaze campaign might get
    public let totalImpressionsMin: Int64

    /// Maximum forecasted impressions a Blaze campaign might get
    public let totalImpressionsMax: Int64

    public init(totalImpressionsMin: Int64, totalImpressionsMax: Int64) {
        self.totalImpressionsMin = totalImpressionsMin
        self.totalImpressionsMax = totalImpressionsMax
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.totalImpressionsMin = try container.decode(Int64.self, forKey: .totalImpressionsMin)
        self.totalImpressionsMax = try container.decode(Int64.self, forKey: .totalImpressionsMax)
    }
}

/// MARK: - Decodable Conformance
///
private extension BlazeImpressions {
    enum CodingKeys: String, CodingKey {
        case totalImpressionsMin = "total_impressions_min"
        case totalImpressionsMax = "total_impressions_max"
    }
}
