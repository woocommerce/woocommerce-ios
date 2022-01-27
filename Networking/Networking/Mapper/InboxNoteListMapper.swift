import Foundation

/// Mapper: Inbox Note List
///
struct InboxNoteListMapper: Mapper {

    /// (Attempts) to convert a dictionary into a Inbox Note Array.
    ///
    func map(response: Data) throws -> [InboxNote] {
        let decoder = JSONDecoder()
        return try decoder.decode([InboxNote].self, from: response)
    }
}
