import Foundation

/// Mapper: `BlazeBillingSummary`
///
struct BlazeBillingSummaryMapper: Mapper {

    /// (Attempts) to convert a dictionary into `BlazeBillingSummary`.
    ///
    func map(response: Data) throws -> BlazeBillingSummary {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(BlazeBillingSummary.self, from: response)
    }
}
