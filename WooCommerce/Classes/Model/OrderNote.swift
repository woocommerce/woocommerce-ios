import Foundation


struct OrderNote: Decodable {
    let identifier: Int
    let dateCreated: String
    let contents: String
    let isCustomerNote: Bool

    init(identifier: Int, dateCreated: String, contents: String, isCustomerNote: Bool) {
        self.identifier = identifier
        self.dateCreated = dateCreated
        self.contents = contents
        self.isCustomerNote = isCustomerNote
    }

    enum OrderNoteStructKeys: String, CodingKey {
        case identifier = "id"
        case dateCreated = "date_created"
        case contents = "note"
        case isCustomerNote = "customer_note"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OrderNoteStructKeys.self)
        let identifier = try container.decode(Int.self, forKey: .identifier)
        let dateCreated = try container.decode(String.self, forKey: .dateCreated)
        let contents = try container.decode(String.self, forKey: .contents)
        let isCustomerNote = try container.decode(Bool.self, forKey: .isCustomerNote)

        self.init(identifier: identifier, dateCreated: dateCreated, contents: contents, isCustomerNote: isCustomerNote)
    }
}
