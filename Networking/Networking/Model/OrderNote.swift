import Foundation

/// Represents an Order's Note Entity.
///
public struct OrderNote: Decodable {
    public let noteID: Int
    public let dateCreated: Date
    public let note: String
    public let isCustomerNote: Bool
    public let author: String

    /// OrderNote struct initializer.
    ///
    public init(noteId: Int, dateCreated: Date, note: String, isCustomerNote: Bool, author: String) {
        self.noteID = noteId
        self.dateCreated = dateCreated
        self.note = note
        self.isCustomerNote = isCustomerNote
        self.author = author
    }

    /// The public initializer for OrderNote.
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let noteId = try container.decode(Int.self, forKey: .noteId)
        let dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        let note = try container.decode(String.self, forKey: .note)
        let isCustomerNote = try container.decode(Bool.self, forKey: .isCustomerNote)
        let author = try container.decode(String.self, forKey: .author)

        self.init(noteId: noteId, dateCreated: dateCreated, note: note, isCustomerNote: isCustomerNote, author: author)  // initialize the struct
    }
}


/// Defines all of the OrderNote's CodingKeys.
///
extension OrderNote {

    fileprivate enum CodingKeys: String, CodingKey {
        case noteId = "id"
        case dateCreated = "date_created_gmt"
        case note = "note"
        case isCustomerNote = "customer_note"
        case author = "author"
    }
}


// MARK: - Comparable Conformance
//
extension OrderNote: Comparable {
    public static func == (lhs: OrderNote, rhs: OrderNote) -> Bool {
        return lhs.noteID == rhs.noteID && lhs.dateCreated == rhs.dateCreated && lhs.note == rhs.note && lhs.isCustomerNote == rhs.isCustomerNote && lhs.author
            == rhs.author
    }

    public static func < (lhs: OrderNote, rhs: OrderNote) -> Bool {
        return lhs.noteID < rhs.noteID || (lhs.noteID == rhs.noteID && lhs.dateCreated < rhs.dateCreated) || (
            lhs.noteID == rhs.noteID && lhs.dateCreated == rhs.dateCreated && lhs.note < rhs.note
        )
    }
}
