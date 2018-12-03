import Foundation


/// Mapper: SitePlan
///
class SitePlanMapper: Mapper {

    /// (Attempts) to convert a dictionary into a [SitePlan].
    ///
    func map(response: Data) throws -> [SitePlan] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)

        return try decoder.decode(SitePlanEnvelope.self, from: response).plan
    }
}

/// SitePlanEnvelope Disposable Entity:
/// The sites/site endpoint returns the plan response within a `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct SitePlanEnvelope: Decodable {
    let plan: [SitePlan]

    private enum CodingKeys: String, CodingKey {
        case plan = "data"
    }
}
