import Foundation
import Storage


// MARK: - Represents a Mutable Entity that can be converted into a ReadOnly Type.
//
public protocol ReadOnlyConvertible: ReadOnlyTypeErasedConvertible {

    /// Represents the ReadOnly Type (mirroring the receiver).
    ///
    associatedtype ReadOnlyType

    /// Updates the Receiver with the ReadOnly Instance.
    ///
    func update(with entity: ReadOnlyType)

    /// Returns a ReadOnly version of the receiver.
    ///
    func toReadOnly() -> ReadOnlyType
}


// MARK: - ReadOnlyConvertible: ErasedConvertible Default Implementation
//
public extension ReadOnlyConvertible {

    /// Returns the (Type Erased) ReadOnly version of the receiver.
    ///
    public func toTypeErasedReadOnly() -> Any? {
        return toReadOnly()
    }
}


// MARK: - Type Erased ReadOnlyConvertible protocol, which allows us to work around several issues, triggered by
//          the `associatedtype` requirements.
//
public protocol ReadOnlyTypeErasedConvertible: class {

    /// Indicates if the receiver represents the Storage version of a given ReadOnly  Type.
    ///
    func represents(readOnlyEntity: Any) -> Bool

    /// Returns a ReadOnly version of the receiver, but with no Type Associated.
    ///
    func toTypeErasedReadOnly() -> Any?
}
