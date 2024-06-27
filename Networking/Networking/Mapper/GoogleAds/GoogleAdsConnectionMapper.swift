import Foundation

/// Mapper: `GoogleAdsConnection`
///
struct GoogleAdsConnectionMapper: Mapper {

    /// (Attempts) to convert a dictionary into `GoogleAdsConnection`.
    ///
    func map(response: Data) throws -> GoogleAdsConnection {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(GoogleAdsConnectionEnvelope.self, from: response).data
        } else {
            return try decoder.decode(GoogleAdsConnection.self, from: response)
        }
    }
}


/// GoogleAdsConnectionEnvelope Disposable Entity:
/// Load Google Ads connection endpoint returns the result in the `data` key.
/// This entity allows us to parse all the things with JSONDecoder.
///
private struct GoogleAdsConnectionEnvelope: Decodable {
    let data: GoogleAdsConnection
}
