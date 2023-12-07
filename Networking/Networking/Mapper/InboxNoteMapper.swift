import Foundation

/// Mapper: Inbox Note
///
struct InboxNoteMapper: Mapper {

    /// Site we're parsing `InboxNote`s for
    /// We're injecting this field by copying it in after parsing response, because `siteID` is not returned in any of the Inbox Note endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into an Inbox Note.
    ///
    func map(response: Data) async throws -> InboxNote {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(InboxNoteEnvelope.self, from: response).data
        } else {
            return try decoder.decode(InboxNote.self, from: response)
        }
    }
}

/// InboxNoteEnvelope Disposable Entity:
/// This entity allows us to parse InboxNote with JSONDecoder.
///
private struct InboxNoteEnvelope: Decodable {
    let data: InboxNote

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
