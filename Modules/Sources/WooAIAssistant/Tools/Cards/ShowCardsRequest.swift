import Foundation

struct ShowCardsRequest: Decodable, Sendable, Equatable {
    let references: [CardReference]

    init(references: [CardReference]) {
        self.references = references
    }
}

struct CardReference: Decodable, Sendable, Equatable {
    let family: CardFamilyID
    /// Raw model-supplied id. For `variation` this is the combined
    /// `{parentProductId}/{variationId}` form; the resolver splits it.
    let id: String

    init(family: CardFamilyID, id: String) {
        self.family = family
        self.id = id
    }

    private enum CodingKeys: String, CodingKey {
        case family
        case id
    }
}

/// One reference's outcome. The resolved/rejected split mirrors the channel
/// boundary in `ToolResult.Success`: only `.resolved` contributes to
/// `uiStructured`, while both contribute to the model-visible `structured`
/// summary so the model can see what it asked for and what it got back.
enum Resolution: Sendable, Equatable {
    case resolved(family: CardFamilyID,
                  id: String,
                  summary: AnyCodableJSON,
                  rendered: RenderedCardPayload)
    case rejected(family: CardFamilyID?,
                  id: String?,
                  reason: CardRefRejectionReason)
}
