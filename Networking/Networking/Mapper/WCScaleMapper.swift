import Foundation

struct WCScaleMapper: Mapper {

    /// (Attempts) to convert a dictionary into a scale status.
    ///
    func map(response: Data) throws -> WCScaleStatus {
        let decoder = JSONDecoder()

        return try decoder.decode(WCScaleEnvelope.self, from: response).status
    }
}

private struct WCScaleEnvelope: Decodable {
    let status: WCScaleStatus

    private enum CodingKeys: String, CodingKey {
        case status = "data"
    }
}
