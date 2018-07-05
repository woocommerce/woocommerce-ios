import Foundation


/// Represents an Order's Note Entity.
///
public struct OrderNote: Decodable {
    public let noteId: Int
    public let dateCreated: Date
    public let contents: String
    public let isCustomerNote: Bool
}


/// Defines all of the OrderNote's CodingKeys.
///
private extension OrderNote {

    enum CodingKeys: String, CodingKey {
        case noteId         = "id"
        case dateCreated    = "date_created_gmt"
        case contents       = "note"
        case isCustomerNote = "customer_note"
    }
}


// MARK: - Comparable Conformance
//
extension OrderNote: Comparable {
    public static func == (lhs: OrderNote, rhs: OrderNote) -> Bool {
        return lhs.noteId == rhs.noteId &&
            lhs.dateCreated == rhs.dateCreated &&
            lhs.contents == rhs.contents &&
            lhs.isCustomerNote == rhs.isCustomerNote
    }

    public static func < (lhs: OrderNote, rhs: OrderNote) -> Bool {
        return lhs.noteId < rhs.noteId ||
            (lhs.noteId == rhs.noteId && lhs.dateCreated < rhs.dateCreated) ||
            (lhs.noteId == rhs.noteId && lhs.dateCreated == rhs.dateCreated && lhs.contents < rhs.contents)
    }
}
