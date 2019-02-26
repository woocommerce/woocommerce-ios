import Foundation


/// Mapper: Order totals report
///
struct ReportOrderTotalsMapper: Mapper {

    /// (Attempts) to extract order totals report from a given JSON Encoded response.
    ///
    func map(response: Data) throws -> [OrderStatus] {
        let decoder = JSONDecoder()
        return try decoder.decode(ReportOrderTotalsEnvelope.self, from: response).data
    }
}

/// The report endpoint returns the totals document within a `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct ReportOrderTotalsEnvelope: Decodable {
    let data: [OrderStatus]

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}
