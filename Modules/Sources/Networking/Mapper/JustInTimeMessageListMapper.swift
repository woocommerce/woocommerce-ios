import Foundation

/// Mapper: Just In Time Message
///
struct JustInTimeMessageListMapper: Mapper {

    /// Site we're parsing `JustInTimeMessage`s for
    /// We're injecting this field by copying it in after parsing response, because `siteID` is not returned in any of the JITM endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert an array into a Just In Time Message.
    ///
    func map(response: Data) throws -> [JustInTimeMessage] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(JustInTimeMessageListEnvelope.self, from: response).data
        } else {
            return try decoder.decode([JustInTimeMessage].self, from: response)
        }
    }
}

/// JustInTimeMessageEnvelope Disposable Entity:
/// This entity allows us to parse JustInTimeMessage with JSONDecoder.
///
private struct JustInTimeMessageListEnvelope: Decodable {
    let data: [JustInTimeMessage]

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
