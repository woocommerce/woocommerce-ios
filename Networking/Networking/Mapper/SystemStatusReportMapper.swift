import Foundation

/// Mapper: System Status Report
///
struct SystemStatusReportMapper: Mapper {

    /// Site Identifier associated to the system status that will be parsed.
    /// We're injecting this field via `JSONDecoder.userInfo` because the remote endpoints don't return the SiteID in the system plugin endpoint.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into SystemStatusReport
    ///
    func map(response: Data) throws -> SystemStatusReport {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(SystemStatusReportEnvelope.self, from: response).systemStatusReport
        } else {
            return try decoder.decode(SystemStatusReport.self, from: response)
        }
    }
}

/// System Status Report endpoint returns the requested account in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
struct SystemStatusReportEnvelope: Decodable {
    let systemStatusReport: SystemStatusReport

    private enum CodingKeys: String, CodingKey {
        case systemStatusReport = "data"
    }
} 