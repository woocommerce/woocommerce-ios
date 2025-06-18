import Foundation
import Codegen

/// Impressions forecast for a Blaze campaign
///
public struct BlazeImpressions: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// Minimum forecasted impressions a Blaze campaign might get
    public let totalImpressionsMin: Int64

    /// Maximum forecasted impressions a Blaze campaign might get
    public let totalImpressionsMax: Int64

    public init(totalImpressionsMin: Int64, totalImpressionsMax: Int64) {
        self.totalImpressionsMin = totalImpressionsMin
        self.totalImpressionsMax = totalImpressionsMax
    }
}
