import Foundation

/// Mapper: WCPay Reader Location
///
struct WCPayReaderLocationMapper: Mapper {

    /// (Attempts) to convert a dictionary into a location.
    ///
    func map(response: Data) throws -> WCPayReaderLocation {
        let decoder = JSONDecoder()

        return try decoder.decode(WCPayReaderLocationEnvelope.self, from: response).location
    }
}

/// WCPayLocationEnvelope Disposable Entity
///
/// Endpoint returns the location in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct WCPayReaderLocationEnvelope: Decodable {
    let location: WCPayReaderLocation

    private enum CodingKeys: String, CodingKey {
        case location = "data"
    }
}
