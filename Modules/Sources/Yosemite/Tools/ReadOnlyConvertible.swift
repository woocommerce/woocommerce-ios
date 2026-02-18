import Foundation
import Storage


// MARK: - Represents a Mutable Entity that can be converted into a ReadOnly Type.
//
public protocol ReadOnlyConvertible: TypeErasedReadOnlyConvertible {

    /// Represents the ReadOnly Type (mirroring the receiver).
    ///
    associatedtype ReadOnlyType

    /// Updates the Receiver with the ReadOnly Instance.
    ///
    func update(with entity: ReadOnlyType)

    /// Returns a ReadOnly version of the receiver.
    ///
    func toReadOnly() -> ReadOnlyType

    /// Returns a lightweight ReadOnly version for list display, skipping expensive relationship conversions.
    /// Default implementation falls back to `toReadOnly()`. Override for entities with costly relationships.
    ///
    func toReadOnlyForListDisplay() -> ReadOnlyType
}

extension ReadOnlyConvertible {
    public func toReadOnlyForListDisplay() -> ReadOnlyType {
        toReadOnly()
    }
}


// MARK: - ReadOnlyConvertible TypeErasure Workaround.
//         This allows us to cast an entity that conforms to ReadOnlyConvertible, without hitting any `associatedtype` issues.
//
public protocol TypeErasedReadOnlyConvertible {

    /// Returns a ReadOnly version of the receiver, but with no Type associated.
    ///
    func toTypeErasedReadOnly() -> Any
}


// MARK: - ReadOnlyConvertible TypeErased Conformance.
//
extension ReadOnlyConvertible {

    /// Returns a ReadOnly version of the receiver, but with no Type associated.
    ///
    public func toTypeErasedReadOnly() -> Any {
        return toReadOnly()
    }
}
