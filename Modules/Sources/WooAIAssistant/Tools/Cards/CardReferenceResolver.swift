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
        var fetchSlots: [Int] = []

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
            fetchSlots.append(index)
        }

        await withTaskGroup(of: (Int, Resolution).self) { group in
            for slot in fetchSlots {
                let reference = bounded[slot]
                group.addTask {
                    let resolution = await fetch(reference: reference)
                    return (slot, resolution)
                }
            }
            for await (slot, resolution) in group {
                resolutions[slot] = resolution
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

    private func fetch(reference: CardReference) async -> Resolution {
        guard let family = registry.family(for: reference.family) else {
            return .rejected(family: reference.family, id: reference.id, reason: .unsupportedFamily)
        }
        switch await family.fetch(reference.id, client) {
        case .found(let entity):
            let summary = family.summarize(entity)
            let rendered = RenderedCardPayload(family: reference.family,
                                               id: reference.id,
                                               element: entity)
            return .resolved(family: reference.family,
                             id: reference.id,
                             summary: summary,
                             rendered: rendered)
        case .rejected(let reason):
            return .rejected(family: reference.family, id: reference.id, reason: reason)
        }
    }

    private struct SeenKey: Hashable {
        let family: CardFamilyID
        let id: Int64
    }
}
