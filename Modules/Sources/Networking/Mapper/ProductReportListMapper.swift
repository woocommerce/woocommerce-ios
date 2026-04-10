import Foundation

/// Mapper: `[ProductReport]`
///
struct ProductReportListMapper: Mapper {

    /// (Attempts) to convert a dictionary into `[ProductReport]`.
    ///
    func map(response: Data) throws -> [ProductReport] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductReportEnvelope.self, from: response).reports
        } else {
            return try decoder.decode([ProductReport].self, from: response)
        }
    }
}

/// ProductReportEnvelope Disposable Entity:
/// Load Product report endpoint returns the report in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct ProductReportEnvelope: Decodable {
    let reports: [ProductReport]

    private enum CodingKeys: String, CodingKey {
        case reports = "data"
    }
}
