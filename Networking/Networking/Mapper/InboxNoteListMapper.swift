import Foundation

/// Mapper: Inbox Note List
///
struct InboxNoteListMapper: Mapper {

    /// Site we're parsing `InboxNote`s for
    /// We're injecting this field by copying it in after parsing responses, because `siteID` is not returned in any of the Inbox Note endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into an Inbox Note Array.
    ///
    func map(response: Data) throws -> [InboxNote] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]
        return try decoder.decode(InboxNoteListEnvelope.self, from: response).data
    }
}

/// InboxNoteListEnvelope Disposable Entity:
/// This entity allows us to parse [InboxNote] with JSONDecoder.
///
private struct InboxNoteListEnvelope: Decodable {
    let data: [InboxNote]

    private enum CodingKeys: String, CodingKey {
        case data
    }
}
