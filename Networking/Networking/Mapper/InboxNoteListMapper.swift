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
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<[InboxNote]>.self, from: response).data
        } else {
            return try decoder.decode([InboxNote].self, from: response)
        }
    }
}
