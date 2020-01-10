import Foundation


/// Mapper: Order totals report
///
struct ReportOrderTotalsMapper: Mapper {

    /// Site Identifier associated to the settings that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because
    /// the remote endpoints don't really return the SiteID in any of the
    /// settings endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to extract order totals report from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> [OrderStatus] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]
        return try decoder.decode(ReportOrderTotalsEnvelope.self, from: response).data
    }
}

/// The report endpoint returns the totals document within a `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct ReportOrderTotalsEnvelope: Decodable {
    let data: [OrderStatus]

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
