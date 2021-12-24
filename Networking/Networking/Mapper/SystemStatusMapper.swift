import Foundation

/// Mapper: System Status
///
struct SystemStatusMapper: Mapper {

    /// Site Identifier associated to the system status that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID in the system plugin endpoint.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into SystemStatus
    ///
    func map(response: Data) throws -> SystemStatus {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        let systemStatus = try decoder.decode(SystemStatusEnvelope.self, from: response).systemStatus
        return systemStatus
    }
}

/// System Status endpoint returns the requested account in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
struct SystemStatusEnvelope: Decodable {
    let systemStatus: SystemStatus

    private enum CodingKeys: String, CodingKey {
        case systemStatus = "data"
    }
}
