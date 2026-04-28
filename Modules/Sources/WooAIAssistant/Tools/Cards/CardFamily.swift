import Foundation

/// `fetch` returns the full entity for the renderer; `summarize` returns the
/// compact projection the model is allowed to see. Letting the model see the
/// entity directly is what causes the 50k-token list-read pathology.
public protocol CardFamily: Sendable {
    static var id: CardFamilyID { get }
    func fetch(id: Int64, client: WCRESTClient) async -> CardFetchOutcome
    func summarize(_ entity: AnyCodableJSON) -> AnyCodableJSON
}

public enum CardFetchOutcome: Sendable {
    case found(AnyCodableJSON)
    case rejected(CardRefRejectionReason)

    /// Default REST status to rejection mapping. Status-only cases route here;
    /// 2xx-with-trashed-payload routes through `.staleReference` directly.
    public static func rejection(forStatusCode statusCode: Int) -> CardRefRejectionReason {
        switch statusCode {
        case 401, 403: return .notPermitted
        case 404: return .notFound
        case 410: return .staleReference
        default: return .fetchFailed
        }
    }
}

public struct AnyCardFamily: Sendable {
    public let id: CardFamilyID
    public let fetch: @Sendable (Int64, WCRESTClient) async -> CardFetchOutcome
    public let summarize: @Sendable (AnyCodableJSON) -> AnyCodableJSON

    public init(id: CardFamilyID,
                fetch: @escaping @Sendable (Int64, WCRESTClient) async -> CardFetchOutcome,
                summarize: @escaping @Sendable (AnyCodableJSON) -> AnyCodableJSON) {
        self.id = id
        self.fetch = fetch
        self.summarize = summarize
    }

    public init<F: CardFamily>(_ family: F) {
        self.id = F.id
        self.fetch = { id, client in await family.fetch(id: id, client: client) }
        self.summarize = { entity in family.summarize(entity) }
    }
}

public struct CardFamilyRegistry: Sendable {
    private let families: [CardFamilyID: AnyCardFamily]

    public init(_ families: [AnyCardFamily]) {
        self.families = Dictionary(uniqueKeysWithValues: families.map { ($0.id, $0) })
    }

    public static func defaultRegistry() -> CardFamilyRegistry {
        CardFamilyRegistry([
            AnyCardFamily(OrderFamily()),
            AnyCardFamily(ProductFamily()),
            AnyCardFamily(CustomerFamily())
        ])
    }

    public func family(for id: CardFamilyID) -> AnyCardFamily? {
        families[id]
    }
}
