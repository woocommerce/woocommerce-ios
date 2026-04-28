import Foundation

public struct ShowCardsRequest: Decodable, Sendable, Equatable {
    public let references: [CardReference]

    public init(references: [CardReference]) {
        self.references = references
    }
}

public struct CardReference: Decodable, Sendable, Equatable {
    public let family: CardFamilyID
    public let id: String

    public init(family: CardFamilyID, id: String) {
        self.family = family
        self.id = id
    }
}

/// One reference's outcome. The resolved/rejected split mirrors the channel
/// boundary in `ToolResult.Success`: only `.resolved` contributes to
/// `uiStructured`, while both contribute to the model-visible `structured`
/// summary so the model can see what it asked for and what it got back.
public enum Resolution: Sendable, Equatable {
    case resolved(family: CardFamilyID,
                  id: String,
                  summary: AnyCodableJSON,
                  rendered: RenderedCardPayload)
    case rejected(family: CardFamilyID?,
                  id: String?,
                  reason: CardRefRejectionReason)
}

public struct ShowCardsResult: Sendable, Equatable {
    public let resolutions: [Resolution]

    public init(resolutions: [Resolution]) {
        self.resolutions = resolutions
    }
}
