import Foundation

/// Render payload a tool can attach to a successful result. Lives app-side
/// only - the orchestrator must never serialize it back into model context,
/// or the model starts parroting the same JSON the renderer is drawing.
public struct UIStructured: Sendable, Equatable {
    public let cards: [RenderedCardPayload]

    public init(cards: [RenderedCardPayload]) {
        self.cards = cards
    }
}

/// One card the renderer will draw. `element` is the family-typed render
/// JSON (full entity for `order` / `product` / `customer` v1 families).
public struct RenderedCardPayload: Sendable, Equatable {
    public let family: CardFamilyID
    public let id: Int64
    public let element: AnyCodableJSON

    public init(family: CardFamilyID, id: Int64, element: AnyCodableJSON) {
        self.family = family
        self.id = id
        self.element = element
    }
}

/// Card families the v1 renderer supports. Coupon / review / refund land
/// in a v2 PR; the catalog is intentionally narrow for the first cut.
public enum CardFamilyID: String, Sendable, Codable, Equatable {
    case order
    case product
    case customer
}
