import Foundation
import Storage

extension StorageCardReaderType: ReadOnlyConvertible {
    /// Required protocol conformance – but not relevant to an enum
    ///
    public func update(with entity: CardReaderType) {
        fatalError("It is not possible to update a CardReaderType, make a new one instead.")
    }

    init(from: CardReaderType) {
        switch from {
        case .chipper:
            self = .chipper
        case .stripeM2:
            self = .stripeM2
        case .wisepad3:
            self = .wisepad3
        case .appleBuiltIn:
            self = .appleBuiltIn
        case .other:
            self = .other
        }
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> CardReaderType {
        switch self {
        case .chipper:
            return .chipper
        case .stripeM2:
            return .stripeM2
        case .wisepad3:
            return .wisepad3
        case .appleBuiltIn:
            return .appleBuiltIn
        case .other:
            return .other
        }
    }
}
