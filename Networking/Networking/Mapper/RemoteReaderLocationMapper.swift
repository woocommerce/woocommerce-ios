import Foundation

/// Mapper: WCPay Reader Location
///
struct RemoteReaderLocationMapper: Mapper {

    /// (Attempts) to convert a dictionary into a location.
    ///
    func map(response: Data) throws -> RemoteReaderLocation {
        let decoder = JSONDecoder()

        return try decoder.decode(RemoteReaderLocationEnvelope.self, from: response).location
    }
}

/// WCPayLocationEnvelope Disposable Entity
///
/// Endpoint returns the location in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct RemoteReaderLocationEnvelope: Decodable {
    let location: RemoteReaderLocation

    private enum CodingKeys: String, CodingKey {
        case location = "data"
    }
}
