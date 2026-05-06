import Foundation

/// Post-validation form of a CardReference; parent id required only for variations.
public struct CardRef: Sendable, Hashable {
    public let family: CardFamily
    public let id: Int64
    public let parentID: Int64?

    public init(family: CardFamily, id: Int64, parentID: Int64?) {
        self.family = family
        self.id = id
        self.parentID = parentID
    }
}

public enum CardEntityOutcome: Sendable {
    case found(CardEntity)
    case rejected(CardRefRejectionReason)
}

/// One fetch transport per card family; the resolver fans out by family.
public protocol CardEntityProvider: Sendable {
    func fetch(refs: [CardRef]) async -> [CardRef: CardEntityOutcome]
}
