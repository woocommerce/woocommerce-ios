import Foundation
import Storage


// MARK: - Represents a Mutable Entity that can be converted into a ReadOnly Type.
//
public protocol ReadOnlyConvertible {

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



// MARK: - TypeErasedConvertible: Allows us to work around several ReadOnlyConvertible issues caused
//         by the `associatedtype` requirements.
//
public protocol TypeErasedConvertible {

    /// Indicates if the receiver represents the Storage version of a given ReadOnly  Type.
    ///
    func represents(entity: Any) -> Bool

    /// Returns a ReadOnly version of the receiver, but with no Type Associated.
    ///
    func toTypeErased() -> Any?
}
