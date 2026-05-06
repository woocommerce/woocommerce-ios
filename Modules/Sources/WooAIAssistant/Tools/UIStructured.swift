public struct UIStructured: Sendable, Equatable {
    let cards: [RenderedCardPayload]

    init(cards: [RenderedCardPayload]) {
        self.cards = cards
    }
}

struct RenderedCardPayload: Sendable, Equatable {
    let family: CardFamily
    let id: String
    let element: AnyCodableJSON

    init(family: CardFamily, id: String, element: AnyCodableJSON) {
        self.family = family
        self.id = id
        self.element = element
    }
}

extension RenderedCardPayload {
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
