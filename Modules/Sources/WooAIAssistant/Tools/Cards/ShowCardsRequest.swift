import Foundation

struct ShowCardsRequest: Decodable, Sendable, Equatable {
    let references: [CardReference]

    init(references: [CardReference]) {
        self.references = references
    }
}

struct CardReference: Decodable, Sendable, Equatable {
    let family: CardFamily
    let id: String
    let parentID: String?

    init(family: CardFamily, id: String, parentID: String? = nil) {
        self.family = family
        self.id = id
        self.parentID = parentID
    }

    private enum CodingKeys: String, CodingKey {
        case family
        case id
        case parentID = "parent_id"
    }
}

/// One reference's outcome. The resolved/rejected split mirrors the channel
/// boundary in `ToolResult.Success`: only `.resolved` contributes to
/// `uiStructured`, while both contribute to the model-visible `structured`
/// summary so the model can see what it asked for and what it got back.
enum Resolution: Sendable, Equatable {
    case resolved(family: CardFamily, id: String, entity: CardEntity)
    case rejected(family: CardFamily?, id: String?, reason: CardRefRejectionReason)
}
