import Foundation

public struct CardReferenceResolver: Sendable {
    public static let maxReferencesPerCall = 10

    private let registry: CardFamilyRegistry
    private let client: WCRESTClient

    public init(registry: CardFamilyRegistry = .defaultRegistry(),
                client: WCRESTClient) {
        self.registry = registry
        self.client = client
    }

    public func resolve(_ references: [CardReference]) async -> ShowCardsResult {
        let bounded = Array(references.prefix(Self.maxReferencesPerCall))
        var resolutions: [Resolution] = Array(repeating: .rejected(family: nil, id: nil, reason: .internalError),
                                              count: bounded.count)
        var seen: Set<SeenKey> = []
        var fetchSlotsByFamily: [CardFamilyID: [(slot: Int, id: Int64)]] = [:]

        for (index, reference) in bounded.enumerated() {
            if reference.id <= 0 {
                resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .malformed)
                continue
            }
            let key = SeenKey(family: reference.family, id: reference.id)
            if seen.contains(key) {
                resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .duplicate)
                continue
            }
            seen.insert(key)
            guard registry.family(for: reference.family) != nil else {
                resolutions[index] = .rejected(family: reference.family, id: reference.id, reason: .unsupportedFamily)
                continue
            }
            fetchSlotsByFamily[reference.family, default: []].append((slot: index, id: reference.id))
        }

        await withTaskGroup(of: (CardFamilyID, [Int64: CardFetchOutcome]).self) { group in
            for (familyID, slots) in fetchSlotsByFamily {
                guard let family = registry.family(for: familyID) else { continue }
                let ids = slots.map { $0.id }
                group.addTask {
                    let outcomes = await family.fetch(ids: ids, client: client)
                    return (familyID, outcomes)
                }
            }
            for await (familyID, outcomes) in group {
                guard let family = registry.family(for: familyID),
                      let slots = fetchSlotsByFamily[familyID] else { continue }
                for entry in slots {
                    let outcome = outcomes[entry.id] ?? .rejected(.notFound)
                    resolutions[entry.slot] = resolution(family: familyID,
                                                         id: entry.id,
                                                         outcome: outcome,
                                                         summarize: family.summarize)
                }
            }
        }

        // Truncate-and-warn on overflow rather than rejecting the whole call:
        // the merchant still gets the first 10 cards, and the model sees a
        // count mismatch big enough to learn from.
        if references.count > Self.maxReferencesPerCall {
            let overflow = references.count - Self.maxReferencesPerCall
            resolutions.append(contentsOf: Array(
                repeating: Resolution.rejected(family: nil, id: nil, reason: .malformed),
                count: overflow
            ))
        }
        return ShowCardsResult(resolutions: resolutions)
    }

    private func resolution(family: CardFamilyID,
                            id: Int64,
                            outcome: CardFetchOutcome,
                            summarize: (AnyCodableJSON) -> AnyCodableJSON) -> Resolution {
        switch outcome {
        case .found(let entity):
            let summary = summarize(entity)
            let rendered = RenderedCardPayload(family: family, id: id, element: entity)
            return .resolved(family: family, id: id, summary: summary, rendered: rendered)
        case .rejected(let reason):
            return .rejected(family: family, id: id, reason: reason)
        }
    }

    private struct SeenKey: Hashable {
        let family: CardFamilyID
        let id: Int64
    }
}
