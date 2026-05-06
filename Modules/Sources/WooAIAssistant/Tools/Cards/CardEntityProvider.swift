import Foundation

/// Post-validation form of a CardReference. `parentID` is meaningful only for
/// `productVariation`; the resolver passes 0 for other families and providers
/// for those families ignore it.
struct CardRef: Sendable, Hashable {
    let family: CardFamily
    let id: Int64
    let parentID: Int64

    init(family: CardFamily, id: Int64, parentID: Int64) {
        self.family = family
        self.id = id
        self.parentID = parentID
    }
}

enum CardEntityOutcome: Sendable {
    case found(CardEntity)
    case rejected(CardRefRejectionReason)
}

/// One fetch transport per card family; the resolver fans out by family.
protocol CardEntityProvider: Sendable {
    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome]
}
