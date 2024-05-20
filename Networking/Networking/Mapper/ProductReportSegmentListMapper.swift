import Foundation

/// Mapper: `[ProductReportSegment]`
///
struct ProductReportSegmentListMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[ProductReportSegment]`.
    ///
    func map(response: Data) throws -> [ProductReportSegment] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductReportEnvelope.self, from: response).report.totals.segments
        } else {
            return try decoder.decode(ProductReport.self, from: response).totals.segments
        }
    }
}

/// ProductReportEnvelope Disposable Entity:
/// Load Product report endpoint returns the report in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct ProductReportEnvelope: Decodable {
    let report: ProductReport

    private enum CodingKeys: String, CodingKey {
        case report = "data"
    }
}
