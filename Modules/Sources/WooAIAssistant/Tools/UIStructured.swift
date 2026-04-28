/// Render payload a tool can attach to a successful result. Lives app-side
/// only - the orchestrator must never serialize it back into model context,
/// or the model starts parroting the same JSON the renderer is drawing.
public struct UIStructured: Sendable, Equatable {
    let cards: [RenderedCardPayload]

    init(cards: [RenderedCardPayload]) {
        self.cards = cards
    }
}

/// One card the renderer will draw. `element` is the family-typed render JSON
/// (the full entity for `order`, `product`, and `customer` families).
struct RenderedCardPayload: Sendable, Equatable {
    let family: CardFamilyID
    let id: String
    let element: AnyCodableJSON

    init(family: CardFamilyID, id: String, element: AnyCodableJSON) {
        self.family = family
        self.id = id
        self.element = element
    }
}

/// Card families the renderer supports. Kept intentionally narrow so each
/// family has a hand-written renderer rather than a generic JSON walker.
enum CardFamilyID: String, Sendable, Decodable, Equatable {
    case order
    case product
    case productVariation = "product_variation"
    case customer
}
