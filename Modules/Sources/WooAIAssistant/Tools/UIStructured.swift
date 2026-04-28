/// Render payload a tool can attach to a successful result. Lives app-side
/// only - the orchestrator must never serialize it back into model context,
/// or the model starts parroting the same JSON the renderer is drawing.
public struct UIStructured: Sendable, Equatable {
    public let cards: [RenderedCardPayload]

    public init(cards: [RenderedCardPayload]) {
        self.cards = cards
    }
}

/// One card the renderer will draw. `element` is the family-typed render JSON
/// (the full entity for `order`, `product`, and `customer` families).
public struct RenderedCardPayload: Sendable, Equatable {
    public let family: CardFamilyID
    public let id: String
    public let element: AnyCodableJSON

    public init(family: CardFamilyID, id: String, element: AnyCodableJSON) {
        self.family = family
        self.id = id
        self.element = element
    }
}

/// Card families the renderer supports. Kept intentionally narrow so each
/// family has a hand-written renderer rather than a generic JSON walker.
public enum CardFamilyID: String, Sendable, Codable, Equatable {
    case order
    case product
    case customer
}
