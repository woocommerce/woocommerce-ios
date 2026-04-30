/// Why a `show_cards` reference did not resolve to a renderable card.
///
/// `malformed` collapses Android's `missingFamily`/`missingID`/`invalidID`
/// triplet because Swift's `Decodable` rejects all three at the same boundary;
/// preserving the sub-distinctions would only surface decoder noise.
enum CardRefRejectionReason: String, Sendable, Equatable {
    case malformed
    case duplicate
    case overLimit
    case notFound
    case notPermitted
    case staleReference
    case fetchFailed
    case internalError

    /// `validated` refs that proceeded to fetch but came back unresolved at the
    /// data layer go into `missing_refs`. The pre-fetch validation rejects go
    /// into `rejected_refs`. The split mirrors Android's structured shape.
    var bucket: Bucket {
        switch self {
        case .malformed, .duplicate, .overLimit:
            return .rejected
        case .notFound, .notPermitted, .staleReference, .fetchFailed, .internalError:
            return .missing
        }
    }

    enum Bucket {
        case missing
        case rejected
    }

    /// Default REST status to rejection mapping. Status-only cases route here;
    /// 2xx-with-trashed-payload routes through `.staleReference` directly.
    static func forStatusCode(_ statusCode: Int) -> CardRefRejectionReason {
        switch statusCode {
        case 401, 403: return .notPermitted
        case 404: return .notFound
        case 410: return .staleReference
        default: return .fetchFailed
        }
    }
}
