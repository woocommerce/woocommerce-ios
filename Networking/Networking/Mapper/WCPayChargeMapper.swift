import Foundation

/// Mapper: WCPayCharge
///
struct WCPayChargeMapper: Mapper {
    let siteID: Int64

    /// (Attempts) to convert a dictionary into an account.
    ///
    func map(response: Data) throws -> WCPayCharge {
        let decoder = JSONDecoder()
        decoder.userInfo = [.siteID: siteID]

        /// Needed for currentDeadline, which is given as a UNIX timestamp.
        /// Unfortunately other properties use other formats for dates, but we
        /// can cross that bridge when we need those decoded.
        decoder.dateDecodingStrategy = .secondsSince1970

        return try decoder.decode(WCPayChargeEnvelope.self, from: response).charge
    }
}

/// WCPayChargeEnvelope Disposable Entity
///
/// Account endpoint returns the requested account in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct WCPayChargeEnvelope: Decodable {
    let charge: WCPayCharge

    private enum CodingKeys: String, CodingKey {
        case charge = "data"
    }
}
