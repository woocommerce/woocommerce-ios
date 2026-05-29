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
/// `analyticsStats` carries an Android-portable synthetic id; its raw value
/// matches the wire family token the model sends. The variation family's
/// wire token is `variation`, kept aligned with woocommerce-android.
enum CardFamilyID: String, Sendable, Decodable, Equatable {
    case order
    case product
    case productVariation = "variation"
    case customer
    case analyticsStats = "analytics_stats"
}

extension RenderedCardPayload {
    /// Analytics returns the kind's tool name directly because `statsCardView`
    /// differentiates revenue vs orders by tool name; entities use the dotted
    /// scheme matched by `MessageCardHost.route(for:)`.
    func syntheticToolName(callName: String) -> String {
        switch family {
        case .analyticsStats:
            return AnalyticsCardSpec.decode(id)?.kind.renderToolName
                ?? "\(callName).\(family.rawValue)"
        case .order, .product, .productVariation, .customer:
            return "\(callName).\(family.rawValue)"
        }
    }
}
