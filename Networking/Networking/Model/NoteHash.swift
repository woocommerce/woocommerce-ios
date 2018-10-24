import Foundation


// MARK: - NoteHash: [ID + Hash] for a given Notification.
//
public struct NoteHash: Decodable {

    /// Notification's Primary Key.
    ///
    public let noteID: Int64

    /// Notification's Hash.
    ///
    public let hash: Int64


    /// Coding Keys
    ///
    private enum CodingKeys: String, CodingKey {
        case noteID = "id"
        case hash = "note_hash"
    }
}
