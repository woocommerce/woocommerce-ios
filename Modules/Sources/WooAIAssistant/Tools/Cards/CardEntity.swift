import Foundation

/// Typed result of resolving a single `show_cards` reference. Cache hits and REST
/// hits converge on the same payload per family so the renderer and the model
/// summary read from one source instead of an `Any`-typed JSON projection.
enum CardEntity: Sendable, Equatable {
    case order(OrderCardPayload)
    case product(ProductCardPayload)
    case variation(ProductVariationCardPayload)
    case customer(CustomerCardPayload)
    case analyticsStats(AnyCodableJSON)
}
