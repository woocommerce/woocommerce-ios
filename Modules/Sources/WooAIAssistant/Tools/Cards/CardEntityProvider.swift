import Foundation

/// Post-validation form of a CardReference; parent id required only for variations.
struct CardRef: Sendable, Hashable {
    let family: CardFamilyID
    let id: Int64
    let parentID: Int64?
}

enum CardEntityOutcome: Sendable {
    case found(CardEntity)
    case rejected(CardRefRejectionReason)
}

/// One fetch transport per card family; the resolver fans out by family.
protocol CardEntityProvider: Sendable {
    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome]
}
