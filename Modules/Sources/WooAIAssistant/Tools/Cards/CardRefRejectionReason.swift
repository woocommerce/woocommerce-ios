/// Why a `show_cards` reference did not resolve to a renderable card.
///
/// `malformed` collapses Android's `missingFamily`/`missingID`/`invalidID`
/// triplet because Swift's `Decodable` rejects all three at the same boundary;
/// preserving the sub-distinctions would only surface decoder noise.
public enum CardRefRejectionReason: String, Sendable, Codable, Equatable {
    case malformed
    case unsupportedFamily
    case duplicate
    case notFound
    case notPermitted
    case staleReference
    case fetchFailed
    case internalError
}
