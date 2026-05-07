import Foundation

/// Post-validation form of a CardReference. `parentID` is meaningful only for
/// `productVariation`; the resolver passes 0 for other families and data sources for those families ignore it.
struct CardRef: Sendable, Hashable {
    let family: CardFamily
    let id: Int64
    let parentID: Int64
}

enum CardEntityOutcome: Sendable {
    case found(CardEntity)
    case rejected(CardRefRejectionReason)
}

/// One fetch transport per card family; the resolver fans out by family.
protocol CardEntityDataSource: Sendable {
    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome]
}
